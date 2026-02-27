require 'selenium-webdriver'

def authorize(authorize_url, target_patient_id: nil, click_scopes: nil)
  options = Selenium::WebDriver::Options.chrome(args: ['--headless=new'])
  driver = Selenium::WebDriver.for(:chrome, options: options)
  wait = Selenium::WebDriver::Wait.new(timeout: 10)
  driver.get authorize_url
  wait.until { driver.find_element(id: "button-#{target_patient_id}") }.click unless target_patient_id.nil?
  submit_button = wait.until { driver.find_element(id: 'submit') }
  click_scopes&.each do |scope|
    scope_checkbox = driver.find_element(:xpath, "//input[@value='#{scope}']")
    scope_checkbox.click
  end
  submit_button.click
  wait.until { driver.find_element(:xpath, '//title') }
  driver.quit
  exit(0)
end
