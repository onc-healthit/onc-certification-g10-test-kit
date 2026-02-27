#!/usr/bin/env bash

# Inferno session CLI orchestration library (requires yq >= 4, jq).
#
# Can be run directly with a YAML config file:
#   bash session_runner.sh my_suite.yaml
# Or sourced as a library; call run_sessions_from_yaml (auto-detects single vs multi).
#
# YAML config format:
#   sessions:                                  # list; first entry used for single-session runs
#     - suite_id: my_suite                     # required
#       name: my_name                          # optional; used to scope rules in multi-session runs
#       preset_id: my-preset                   # optional
#       suite_options:                         # optional
#         option_key: option_value
#       expected_results_file: expected.json   # optional; relative to yaml file
#                                              # default: <yaml_name>_expected.json
#   rules:                                     # ordered; first match wins
#     - status: created                        # created, done, or waiting;
#                                              # running/queued/cancelling handled automatically
#       last_test: ""                          # optional; absent treated as ""; must match exactly
#       session: my_name                       # optional; in multi-session, scopes rule to named session
#       command: "bundle exec inferno session start_run '{session_id}' -r 5"
#                                              # required; eval used to execute as the next step
#       timeout: 300                           # optional; seconds before execution stops waiting
#       next_poll_session: other_name          # optional; switch polling to named session after command
#       state_description: "..."               # optional; logged when rule is matched
#       action_description: "..."              # optional; logged after state_description
#

# ── Template tokens in 'command' ─────────────────────────────────────────────
#   {session_id}             – ID of the current (rule-matched) session; single-session only
#   {session_id.NAME}        – ID of the session with the given name or suite_id; required in multi-session
#   {result_message}         – wait result message from the current session
#   {NAME.result_message}    – wait result message from the named session (triggers a status call)
#   {wait_outputs.KEY}       – wait output KEY from the current session
#   {NAME.wait_outputs.KEY}  – wait output KEY from the named session (triggers a status call)
#
# ── Special command values ────────────────────────────────────────────────────
#   "END_SCRIPT"       – end execution for this session (explicit terminal rule)
#   "NOOP"             – rule matched but take no action; keep polling with unchanged timeout
#
# ── Automatic status handling (no rules needed) ───────────────────────────────
#   running/queued/cancelling        → poll again
#   done (no rule matched)           → warn, run comparison, exit non-zero
#   waiting (no rule matched)        → cancel run and continue polling
#   created (no rule matched)        → warn, run comparison, exit non-zero

POLL_INTERVAL="${POLL_INTERVAL:-5}"              # seconds between status checks
DEFAULT_POLL_TIMEOUT="${DEFAULT_POLL_TIMEOUT:-600}"  # default timeout for poll_until_action
# 'session compare' flags – all enabled by default; set to empty to disable:
#   COMPARE_NORMALIZE        – -n: normalize UUIDs and base64 values before comparing (default: on)
#   COMPARE_MESSAGES         – -m: compare messages array (default: on)
#   COMPARE_RESULT_MESSAGE   – -r: compare result_message string (default: on)
COMPARE_NORMALIZE="${COMPARE_NORMALIZE:-true}"
COMPARE_MESSAGES="${COMPARE_MESSAGES:-true}"
COMPARE_RESULT_MESSAGE="${COMPARE_RESULT_MESSAGE:-true}"

# Substitute all template tokens in CMD and print the result to stdout.
# Returns 1 (with a message to stderr) if any token cannot be resolved.
# Set INFERNO_URL to pass -I to cross-session status calls.
#
# Usage: apply_command_templates CMD SESSION_ID STATUS_JSON [ALL_SESSIONS_JSON]
apply_command_templates() {
  local cmd="$1"
  local session_id="$2"
  local status_json="$3"
  local all_sessions_json="${4:-}"

  cmd="${cmd//\{session_id\}/$session_id}"
  while [[ "$cmd" =~ \{session_id\.([^}]+)\} ]]; do
    local sname="${BASH_REMATCH[1]}"
    local sid
    sid=$(printf '%s' "$all_sessions_json" | jq -r --arg n "$sname" '.[$n] // ""')
    if [[ -z "$sid" ]]; then
      printf 'template: {session_id.%s} – session "%s" not found in sessions map\n' "$sname" "$sname" >&2
      return 1
    fi
    cmd="${cmd//\{session_id.$sname\}/$sid}"
  done

  local result_message result_message_q
  result_message=$(printf '%s' "$status_json" | jq -r '.wait_result_message // ""')
  if [[ "$cmd" == *"{result_message}"* && -z "$result_message" ]]; then
    printf 'template: {result_message} is empty for session %s\n' "$session_id" >&2
    return 1
  fi
  result_message_q=$(printf '%q' "$result_message")
  cmd="${cmd//\{result_message\}/$result_message_q}"

  while [[ "$cmd" =~ \{wait_outputs\.([^}]+)\} ]]; do
    local key="${BASH_REMATCH[1]}"
    local value
    value=$(printf '%s' "$status_json" | jq -r --arg key "$key" \
      '.wait_outputs[] | select(.name == $key) | .value')
    if [[ -z "$value" ]]; then
      printf 'template: {wait_outputs.%s} – key "%s" not found in wait_outputs for session %s\n' \
        "$key" "$key" "$session_id" >&2
      return 1
    fi
    cmd="${cmd//\{wait_outputs.$key\}/$value}"
  done

  # Cross-session substitutions – fetch status for the named session on demand
  while [[ "$cmd" =~ \{([^}.]+)\.result_message\} ]]; do
    local sname="${BASH_REMATCH[1]}"
    local sid
    sid=$(printf '%s' "$all_sessions_json" | jq -r --arg n "$sname" '.[$n] // ""')
    if [[ -z "$sid" ]]; then
      printf 'template: {%s.result_message} – session "%s" not found in sessions map\n' "$sname" "$sname" >&2
      return 1
    fi
    local other_status other_msg other_msg_q
    other_status=$(bundle exec inferno session status "$sid" ${INFERNO_URL:+-I "$INFERNO_URL"})
    other_msg=$(printf '%s' "$other_status" | jq -r '.wait_result_message // ""')
    if [[ -z "$other_msg" ]]; then
      printf 'template: {%s.result_message} is empty for session %s\n' "$sname" "$sid" >&2
      return 1
    fi
    other_msg_q=$(printf '%q' "$other_msg")
    cmd="${cmd//\{$sname.result_message\}/$other_msg_q}"
  done

  while [[ "$cmd" =~ \{([^}.]+)\.wait_outputs\.([^}]+)\} ]]; do
    local sname="${BASH_REMATCH[1]}"
    local key="${BASH_REMATCH[2]}"
    local sid
    sid=$(printf '%s' "$all_sessions_json" | jq -r --arg n "$sname" '.[$n] // ""')
    if [[ -z "$sid" ]]; then
      printf 'template: {%s.wait_outputs.%s} – session "%s" not found in sessions map\n' \
        "$sname" "$key" "$sname" >&2
      return 1
    fi
    local other_status other_value
    other_status=$(bundle exec inferno session status "$sid" ${INFERNO_URL:+-I "$INFERNO_URL"})
    other_value=$(printf '%s' "$other_status" | jq -r --arg key "$key" \
      '.wait_outputs[] | select(.name == $key) | .value')
    if [[ -z "$other_value" ]]; then
      printf 'template: {%s.wait_outputs.%s} – key "%s" not found in wait_outputs for session %s\n' \
        "$sname" "$key" "$key" "$sid" >&2
      return 1
    fi
    cmd="${cmd//\{$sname.wait_outputs.$key\}/$other_value}"
  done

  # Auto-append -I for inferno CLI commands when INFERNO_URL is set
  [[ "$cmd" == *"bundle exec inferno"* && -n "$INFERNO_URL" ]] && \
    cmd+=" -I '$INFERNO_URL'"

  printf '%s' "$cmd"
}

# Default implementation – reads rules from a YAML config file via yq + jq.
# Override by defining next_action_from_status after sourcing this file.
# Usage: next_action_from_status STATUS_JSON [SESSION_NAME [ALL_SESSIONS_JSON]]
next_action_from_status() {
  local status_json="$1"
  local session_name="${2:-}"
  local all_sessions_json="${3:-}"
  local config_file="${ACTIONS_FILE:-$(dirname "$0")/$(basename "$0" .sh).yaml}"

  if [[ ! -f "$config_file" ]]; then
    printf 'next_action_from_status: config file not found: %s\n' "$config_file" >&2
    return 1
  fi

  local status session_id last_test
  status=$(printf '%s' "$status_json" | jq -r '.status')
  session_id=$(printf '%s' "$status_json" | jq -r '.test_session_id')
  last_test=$(printf '%s' "$status_json" | jq -r '.last_test_executed // ""')

  local rule
  rule=$(yq -o=json "$config_file" | jq \
    --arg status "$status" \
    --arg last_test "$last_test" \
    --arg session_name "$session_name" \
    '[.rules[] | select(
      ($session_name == "" or (.session // "") == "" or .session == $session_name) and
      .status == $status and
      (.last_test // "") == $last_test
    )] | .[0]')

  if [[ -z "$rule" || "$rule" == "null" ]]; then
    # No rule matched – return empty; caller applies defaults:
    #   done/created → emit UNMATCHED
    #   waiting      → cancel run and continue polling
    return 0
  fi

  local cmd
  cmd=$(printf '%s' "$rule" | jq -r '.command // empty')

  # No command field – delegate to caller (poll again / UNMATCHED / cancel)
  [[ -z "$cmd" ]] && return 0

  local rule_session rule_state_description rule_action_description rule_next_poll_session rule_timeout
  rule_session=$(printf '%s' "$rule" | jq -r '.session // empty')
  rule_state_description=$(printf '%s' "$rule" | jq -r '.state_description // empty')
  rule_action_description=$(printf '%s' "$rule" | jq -r '.action_description // empty')
  rule_next_poll_session=$(printf '%s' "$rule" | jq -r '.next_poll_session // empty')
  rule_timeout=$(printf '%s' "$rule" | jq -r '.timeout // empty')
  printf '\nMatched rule:%s\n  status=%s last_test=%s%s\n  Command: %s%s%s%s\n' \
    "${rule_state_description:+ $rule_state_description}" \
    "$status" \
    "${last_test:-(none)}" \
    "${rule_session:+ session=$rule_session}" \
    "$cmd" \
    "${rule_action_description:+$'\n  Action: '$rule_action_description}" \
    "${rule_next_poll_session:+$'\n  Next poll session: '$rule_next_poll_session}" \
    "${rule_timeout:+$'\n  Timeout: '$rule_timeout}" >&2

  cmd=$(apply_command_templates "$cmd" "$session_id" "$status_json" "$all_sessions_json") || return 1
  printf '%s\n%s\n%s\n' "$cmd" "${rule_timeout}" "${rule_next_poll_session}"
}

# Poll 'session status' every $POLL_INTERVAL seconds until the run leaves the
# 'running' state. Echoes the command and resolved timeout on separate lines
# and exits 0 on a recognized non-running state; exits 1 on timeout or error.
# Set INFERNO_URL to pass -I to every status call.
#
# Output (three lines for non-UNMATCHED results):
#   UNMATCHED                                        – no rule matched; session ended unexpectedly
#   <command>\n<timeout>\n<next_polling_session>     – command, timeout (seconds), optional next session key
#
# Usage: poll_until_action SESSION_ID [TIMEOUT_SECONDS [ALL_SESSIONS_JSON [SESSION_KEY]]]
#
# Mirrors pause_until_waiting / pause_until_done in session_controller.rb:
# call once after start_run; eval the result to handle a waiting step,
# or check for UNMATCHED to detect an unexpected terminal state.
poll_until_action() {
  local session_id="$1"
  local timeout="${2:-$DEFAULT_POLL_TIMEOUT}"
  local all_sessions_json="${3:-}"
  local session_key="${4:-}"
  local elapsed=0
  local last_logged=0

  while (( elapsed < timeout )); do
    local status_json run_status
    status_json=$(bundle exec inferno session status "$session_id" \
      ${INFERNO_URL:+-I "$INFERNO_URL"})
    run_status=$(printf '%s' "$status_json" | jq -r '.status')

    # running/queued/cancelling → poll again automatically
    if [[ "$run_status" == "running" || "$run_status" == "queued" || "$run_status" == "cancelling" ]]; then
      sleep "$POLL_INTERVAL"
      (( elapsed += POLL_INTERVAL ))
      if (( elapsed - last_logged >= 30 )); then
        local poll_last_test
        poll_last_test=$(printf '%s' "$status_json" | jq -r '.last_test_executed // "(none)"')
        printf '  [polling] elapsed=%ds  status=%s  last_test=%s\n' \
          "$elapsed" "$run_status" "$poll_last_test" >&2
        last_logged=$elapsed
      fi
      continue
    fi

    local action
    action=$(next_action_from_status "$status_json" "$session_key" "$all_sessions_json") || return 1

    if [[ -n "$action" ]]; then
      local cmd next_timeout next_session
      { IFS= read -r cmd; IFS= read -r next_timeout; IFS= read -r next_session; } <<< "$action"
      printf '%s\n%s\n%s\n' "$cmd" "${next_timeout:-$DEFAULT_POLL_TIMEOUT}" "${next_session}"
      return 0
    fi

    if [[ "$run_status" == "done" || "$run_status" == "created" ]]; then
      local done_last_test
      done_last_test=$(printf '%s' "$status_json" | jq -r '.last_test_executed // ""')
      printf 'No rule matched for status=%s last_test=%s; ending session\n' \
        "$run_status" "$done_last_test" >&2
      echo "UNMATCHED"
      return 0
    fi

    if [[ "$run_status" == "waiting" ]]; then
      local wait_last_test
      wait_last_test=$(printf '%s' "$status_json" | jq -r '.last_test_executed // ""')
      printf 'Unhandled wait state (last_test=%s); cancelling current run for session %s\n' \
        "$wait_last_test" "$session_id" >&2
      bundle exec inferno session cancel_run "$session_id" \
        ${INFERNO_URL:+-I "$INFERNO_URL"} >&2 || return 1
      sleep "$POLL_INTERVAL"
      (( elapsed += POLL_INTERVAL ))
      if (( elapsed - last_logged >= 30 )); then
        printf '  [polling] elapsed=%ds  status=%s  last_test=%s\n' \
          "$elapsed" "$run_status" "${wait_last_test:-(none)}" >&2
        last_logged=$elapsed
      fi
      continue
    fi

    printf 'poll_until_action: unexpected status %s for session %s\n' "$run_status" "$session_id" >&2
    return 1
  done

  printf 'poll_until_action: timed out after %ds (session %s)\n' \
    "$timeout" "$session_id" >&2
  return 1
}

# Create an Inferno session and echo its ID to stdout.
# Informational messages are written to stderr.
# Set INFERNO_URL to pass -I to every API call.
#
# Usage: create_session SUITE_ID [-p PRESET_ID] [-o KEY:VAL ...]
#   SUITE_ID  – suite id passed to 'session create'
#   -p        – preset id to apply when creating the session
#   -o KEY:VAL – suite option(s); repeat KEY:VAL pairs as needed
create_session() {
  local suite_id="$1"
  shift

  local preset_id=""
  local suite_opts_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p) shift; preset_id="$1"; shift ;;
      -o)
        shift
        while [[ $# -gt 0 && "$1" == *:* ]]; do
          suite_opts_args+=("$1"); shift
        done
        ;;
      *) printf 'create_session: unknown argument: %s\n' "$1" >&2; return 1 ;;
    esac
  done

  local create_cmd=(bundle exec inferno session create "$suite_id")
  [[ -n "$preset_id" ]] && create_cmd+=(-p "$preset_id")
  [[ ${#suite_opts_args[@]} -gt 0 ]] && create_cmd+=(-o "${suite_opts_args[@]}")
  [[ -n "$INFERNO_URL" ]] && create_cmd+=(-I "$INFERNO_URL")

  printf "Creating '%s' session...\n" "$suite_id" >&2
  local session_json
  if ! session_json=$("${create_cmd[@]}"); then
    printf 'create_session: session create failed for suite %s\n' "$suite_id" >&2
    return 1
  fi
  local session_id
  session_id=$(printf '%s' "$session_json" | jq -r '.id')
  if [[ -z "$session_id" || "$session_id" == "null" ]]; then
    printf 'create_session: session create returned no id (suite %s)\n' "$suite_id" >&2
    return 1
  fi
  printf 'Session created: %s\n' "$session_id" >&2
  echo "$session_id"
}

# For each session in SESSIONS_JSON, compare results against the expected file
# (if it exists) or write results to the expected file path (if it doesn't).
# Returns the lowest non-zero exit code from any compare call, or 0.
# Usage: compare_or_save_sessions SESSIONS_JSON
compare_or_save_sessions() {
  local sessions_json="$1"
  local compare_result=0
  local entry
  while IFS= read -r entry; do
    local sid ef
    sid=$(printf '%s' "$entry" | jq -r '.id')
    ef=$(printf '%s' "$entry" | jq -r '.expected_results_file // empty')
    if [[ -f "$ef" ]]; then
      local session_key compare_output compare_exit
      session_key=$(printf '%s' "$entry" | jq -r '.key // empty')
      compare_output=$(bundle exec inferno session compare "$sid" \
        -f "$ef" \
        ${COMPARE_NORMALIZE:+-n} \
        ${COMPARE_MESSAGES:+-m} \
        ${COMPARE_RESULT_MESSAGE:+-r} \
        ${INFERNO_URL:+-I "$INFERNO_URL"})
      compare_exit=$?
      printf 'Compare results (%s): matched=%s\n' \
        "$session_key" "$(printf '%s' "$compare_output" | jq -r '.matched')"
      (( compare_exit != 0 && (compare_result == 0 || compare_exit < compare_result) )) && compare_result=$compare_exit
    elif [[ -n "$ef" ]]; then
      echo "Expected results file not found; writing results to '$ef'..."
      bundle exec inferno session results "$sid" \
        ${INFERNO_URL:+-I "$INFERNO_URL"} > "$ef"
    fi
  done < <(printf '%s' "$sessions_json" | jq -c '.[]')
  return $compare_result
}

# Run the poll loop across one or more pre-created sessions until all runs are done.
# Polling starts at the first entry and switches whenever a rule returns next_poll_session.
# Set INFERNO_URL to pass -I to every API call.
#
# Usage: run_sessions SESSIONS_JSON
#   SESSIONS_JSON  – JSON array ordered by start sequence:
#                    [{"key":"name","id":"session-id","expected_results_file":"path"}, ...]
#                    expected_results_file is optional per entry.
run_sessions() {
  local sessions_json="$1"

  local current_key
  current_key=$(printf '%s' "$sessions_json" | jq -r '.[0].key')

  # Build name→id map for {session_id.NAME} substitution
  local all_sessions_map
  all_sessions_map=$(printf '%s' "$sessions_json" | jq 'map({(.key): .id}) | add // {}')

  local timeout="$DEFAULT_POLL_TIMEOUT"
  local unmatched_done=false
  while true; do
    local session_id
    session_id=$(printf '%s' "$sessions_json" | jq -r --arg key "$current_key" \
      '.[] | select(.key == $key) | .id')

    printf '\nPolling session: %s (%s) timeout=%s\n' "$current_key" "$session_id" "$timeout" >&2
    local output
    output=$(poll_until_action "$session_id" "$timeout" "$all_sessions_map" "$current_key") || return 1
    local cmd next_session
    # Read all three fields up front so NOOP can update timeout and current_key
    # before continuing the loop (UNMATCHED/END_SCRIPT don't need them).
    { IFS= read -r cmd; IFS= read -r timeout; IFS= read -r next_session; } <<< "$output"
    if [[ "$cmd" == "UNMATCHED" ]]; then
      unmatched_done=true
      break
    fi
    if [[ "$cmd" == "END_SCRIPT" ]]; then
      break
    fi
    [[ -n "$next_session" ]] && current_key="$next_session"
    if [[ "$cmd" == "NOOP" ]]; then
      continue
    fi
    echo "Executing: $cmd"
    local cmd_output
    if ! cmd_output=$(eval "$cmd"); then
      printf '%s\n' "$cmd_output" >&2
      return 1
    fi
  done

  echo "All runs complete."

  [[ "$unmatched_done" == "true" ]] && return 1
  compare_or_save_sessions "$sessions_json"
}

# Create an Inferno session from a single YAML sessions[] entry.
# Prints a JSON object {"key":...,"id":...,"expected_results_file":...} to stdout.
# Set INFERNO_URL to pass -I to the create call.
#
# Usage: create_session_from_yaml_config SESSION_CONFIG YAML_FILE SESSION_COUNT
create_session_from_yaml_config() {
  local session_config="$1"
  local yaml_file="$2"
  local session_count="$3"

  local suite_id
  suite_id=$(printf '%s' "$session_config" | jq -r '.suite_id')
  if [[ -z "$suite_id" || "$suite_id" == "null" ]]; then
    printf 'create_session_from_yaml_config: suite_id is required\n' >&2
    return 1
  fi

  local session_name
  session_name=$(printf '%s' "$session_config" | jq -r '.name // empty')
  local session_key="${session_name:-$suite_id}"

  local create_args=("$suite_id")
  local preset_id
  preset_id=$(printf '%s' "$session_config" | jq -r '.preset_id // empty')
  [[ -n "$preset_id" ]] && create_args+=(-p "$preset_id")

  local opts_array=()
  while IFS= read -r opt; do
    [[ -n "$opt" ]] && opts_array+=("$opt")
  done < <(printf '%s' "$session_config" | \
    jq -r '.suite_options // {} | to_entries[] | "\(.key):\(.value)"')
  [[ ${#opts_array[@]} -gt 0 ]] && create_args+=(-o "${opts_array[@]}")

  local session_id
  session_id=$(create_session "${create_args[@]}") || return 1

  # Expected results file; relative paths resolved relative to the yaml file
  local expected_results_file
  expected_results_file=$(printf '%s' "$session_config" | jq -r '.expected_results_file // empty')
  if [[ -n "$expected_results_file" ]]; then
    [[ "$expected_results_file" != /* ]] && \
      expected_results_file="$(dirname "$yaml_file")/$expected_results_file"
  elif [[ "$session_count" -eq 1 ]]; then
    expected_results_file="$(dirname "$yaml_file")/$(basename "$yaml_file" .yaml)_expected.json"
  else
    expected_results_file="$(dirname "$yaml_file")/$(basename "$yaml_file" .yaml)_${session_key}_expected.json"
  fi

  jq -n --arg key "$session_key" --arg id "$session_id" --arg ef "$expected_results_file" \
    '{"key": $key, "id": $id, "expected_results_file": $ef}'
}

# Run sessions defined entirely by a YAML config file (session configs + rules).
# Creates all sessions listed under 'sessions:' and runs the poll loop.
# Set INFERNO_URL to pass -I to every API call.
#
# Usage: run_sessions_from_yaml YAML_FILE
run_sessions_from_yaml() {
  local yaml_file="$1"

  if [[ -z "$yaml_file" ]]; then
    printf 'Usage: run_sessions_from_yaml <yaml_file>\n' >&2
    return 1
  fi

  if [[ ! -f "$yaml_file" ]]; then
    printf 'run_sessions_from_yaml: file not found: %s\n' "$yaml_file" >&2
    return 1
  fi

  # Resolve to absolute path so relative paths inside the YAML resolve correctly
  yaml_file="$(cd "$(dirname "$yaml_file")" && pwd)/$(basename "$yaml_file")"

  export ACTIONS_FILE="$yaml_file"

  local yaml_json
  yaml_json=$(yq -o=json "$yaml_file")

  local session_count
  session_count=$(printf '%s' "$yaml_json" | jq '.sessions | length')

  # Create all sessions and build the sessions array
  local sessions_array="[]"
  local i
  for (( i=0; i<session_count; i++ )); do
    local entry
    entry=$(create_session_from_yaml_config \
      "$(printf '%s' "$yaml_json" | jq ".sessions[$i]")" \
      "$yaml_file" "$session_count") || return 1
    sessions_array=$(printf '%s' "$sessions_array" | jq --argjson e "$entry" '. + [$e]')
  done

  run_sessions "$sessions_array"
}

# When executed directly (not sourced), run the YAML file passed as the first argument
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_sessions_from_yaml "$1"
  exit $?
fi
