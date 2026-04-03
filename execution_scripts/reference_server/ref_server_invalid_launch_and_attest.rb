begin
  require 'selenium-webdriver'
rescue LoadError
  warn 'selenium-webdriver is required to run this command script.'
  warn "Add it to your Gemfile: gem 'selenium-webdriver'"
  exit(1)
end

launch_url = ARGV[0]
attest_url = ARGV[1]

options = Selenium::WebDriver::Options.chrome(args: ['--headless=new'])
driver = Selenium::WebDriver.for(:chrome, options: options)
wait = Selenium::WebDriver::Wait.new(timeout: 10)
driver.get launch_url
wait.until { driver.find_element(id: 'errorMessage') }
driver.get attest_url
wait.until { driver.find_element(:xpath, '//title') }
driver.quit
exit(0)
