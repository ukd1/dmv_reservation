require 'rubygems'
require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'
require 'ap'
require 'chronic'
require 'pry-byebug'
require 'yaml'

def debug?
  true
end

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.default_driver = :selenium

class Page
  include Capybara::DSL

  attr_reader :data

  def initialize(data)
    @data = data
  end

  def debug(object)
    ap object if debug?
  end

  def perform
    target_date = Date.today + 7

    while true
      begin
        fill_form
        # save_and_open_page('dmv.html')

        puts "Next Available #{next_available}"

        if next_available < target_date
          return book_apointment
        else
          sleep 30
        end
      rescue => e
        puts "Exception #{e.class} #{e.message}"
        puts e.backtrace.join("\n")
      end
    end
  end

  def book_apointment
    click_button 'Schedule Appointment Selected'
    click_button 'Confirm'
    send_email_confirmation
  end

  def fill_form
    visit('https://www.dmv.ca.gov/wasapp/foa/clear.do?goTo=officeVisit&localeName=en')
    sleep 2
    within('[name="ApptForm"]') do
      select data.office, from: 'officeId'
      choose '1 item'
      check 'taskDL'
      fill_in 'fdlNumber', with: data.licence
      fill_in 'firstName', with: data.first_name
      fill_in 'lastName', with: data.last_name
      fill_in 'telArea', with:  data.tel_area
      fill_in 'telPrefix', with: data.tel_prefix
      fill_in 'telSuffix', with: data.tel_suffix
    end
    click_button 'Submit'
  end

  def send_email_confirmation
    fill_in 'emailAdd', with: data.email

    click_button 'Send Email Confirmation'
  end

  def next_available
    fields = all(:css, 'table tr p strong')
    date = fields[0].text
    # puts date
    date = date.split(', ')[1..-1].join(' ')
    Chronic.parse(date).to_date
  end
end

class ConfigData < OpenStruct
  def self.from_file(path)
    hash = YAML.load(File.read(path))
    new(hash)
  end

  def first_name
    name.split.first.upcase
  end

  def last_name
    name.split.last.upcase
  end

  def tell_parts
    tel.split('-')
  end

  def tel_area
    tell_parts[0]
  end

  def tel_prefix
    tell_parts[1]
  end

  def tel_suffix
    tell_parts[2]
  end
end

data = ConfigData.from_file('data.yml')
Page.new(data).perform

puts 'done'
