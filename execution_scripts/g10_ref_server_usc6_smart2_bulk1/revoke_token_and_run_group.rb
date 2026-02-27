require_relative '../revoke_token'

session_id = ARGV[0]
revoke_token_group = ARGV[1]
inferno_host = ARGV[2]

revoke_token(session_id, inferno_host)
start_run_cli_command =
  "bundle exec inferno session start_run #{session_id} " \
  "-r #{revoke_token_group}#{" -I #{inferno_host}" unless inferno_host.nil?}"
exec(start_run_cli_command)
