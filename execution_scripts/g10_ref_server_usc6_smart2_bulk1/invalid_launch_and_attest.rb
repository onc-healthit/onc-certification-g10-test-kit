require 'selenium-webdriver'

launch_url = ARGV[0].split('(')[1].split(')').first
attest_url = ARGV[0].split('(')[2].split(')').first

options = Selenium::WebDriver::Options.chrome(args: ['--headless=new'])
driver = Selenium::WebDriver.for(:chrome, options: options)
wait = Selenium::WebDriver::Wait.new(timeout: 10)
driver.get launch_url
wait.until { driver.find_element(id: 'errorMessage') }
driver.get attest_url
wait.until { driver.find_element(:xpath, '//title') }
driver.quit
exit(0)
