begin
  require 'selenium-webdriver'
rescue LoadError
  warn 'selenium-webdriver is required to run this command script.'
  warn "Add it to your Gemfile: gem 'selenium-webdriver'"
  exit(1)
end

def ref_server_revoke_token(session_id, inferno_host)
  inputs_cli_command = "bundle exec inferno session data #{session_id}#{" -I #{inferno_host}" unless inferno_host.nil?}"
  inputs = JSON.parse(`#{inputs_cli_command}`)

  token_to_revoke = token_to_revoke(inputs)
  raise StandardError, 'could not find access token to revoke' if token_to_revoke.nil? || token_to_revoke == ''

  reference_server_url = inputs.find { |input| input['name'] == 'url' }&.dig('value')
  revocation_url = "#{reference_server_url.chomp('/r4')}/oauth/token/revoke-token"

  options = Selenium::WebDriver::Options.chrome(args: ['--headless=new'])
  driver = Selenium::WebDriver.for(:chrome, options: options)
  wait = Selenium::WebDriver::Wait.new(timeout: 10)
  driver.get revocation_url
  wait.until { driver.find_element(id: 'revokeToken') }.send_keys(token_to_revoke)
  driver.find_element(id: 'revokeTokenButton').click
  wait.until { driver.find_element(id: 'errorMessage').text.include?('successfully') }
  driver.quit
end

def token_to_revoke(inputs)
  JSON.parse(inputs.find { |input| input['name'] == 'smart_auth_info' }&.dig('value'))&.dig('access_token')
rescue JSON::ParserError
  nil
end

session_id = ARGV[0]
revoke_token_group = ARGV[1]
inferno_host = ARGV[2]

ref_server_revoke_token(session_id, inferno_host)
start_run_cli_command =
  "bundle exec inferno session start_run #{session_id} #{revoke_token_group}" \
  "#{" -I #{inferno_host}" unless inferno_host.nil?}"
exec(start_run_cli_command)
