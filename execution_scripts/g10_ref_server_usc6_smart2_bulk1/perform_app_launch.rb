require 'selenium-webdriver'

launch_url = ARGV[0].split('`')[1]
reference_server_url = ARGV[0].split('`')[5].chomp('/r4')
launch_screen_url = "#{reference_server_url}/app/app-launch"

options = Selenium::WebDriver::Options.chrome(args: ['--headless=new'])
driver = Selenium::WebDriver.for(:chrome, options: options)
wait = Selenium::WebDriver::Wait.new(timeout: 10)
driver.get launch_screen_url
wait.until { driver.find_element(id: 'patientSelector').text.include?('85') }
driver.find_element(id: 'appURI').send_keys(launch_url)
driver.find_element(id: 'launchAppButton').click
wait.until { driver.find_element(:xpath, "//h2[text()='User Action Required']") }
driver.quit
exit(0)
