# frozen_string_literal: true 

# Base class  for system tests

require 'spec_helper'

require 'capybara/rails'
require 'capybara/minitest'
require  'capybara/cuprite'

require 'evil_systems'

# In CI, assets should already be pre-compiled, so skip the default task
if ENV.fetch('CI', false) == 'true'
    EvilSystems.initial_setup(skip_task: true)
  else
    EvilSystems.initial_setup
  end
  
  # base class for system tests
  class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
    include MoneyRails::ActionViewExtension
    include ActionView::Helpers::NumberHelper
    include ActionView::RecordIdentifier
    MAX_WAIT_TIME = 10
  
    driven_by :evil_cuprite
  
    include EvilSystems::Helpers
  
    Capybara.configure do |config|
      # try a longer default wait time, original was 5.
      config.default_max_wait_time = MAX_WAIT_TIME
    end
  
    setup do
      Capybara.page.current_window.resize_to(1350, 900)
    end
  
    delegate :driver, :document, to: :page, prefix: false
    delegate :wait_for_network_idle, to: :driver, prefix: false
    delegate :synchronize, to: :document, prefix: false
  
    # Call with a block and any screenshots taken within will have a copy of the html
    def with_screenshot_html
      return unless block_given?
  
      'RAILS_SYSTEM_TESTING_SCREENSHOT_HTML'.tap do |html_env_key|
        yield && next if ENV[html_env_key] == '1'
  
        ENV.store html_env_key, '1'
        yield
        ENV.delete html_env_key
      end
    end
  
    # Yield to the block and take a screenshot if there is an exception
    def screenshot_on_error
      yield if block_given?
    rescue Minitest::UnexpectedError
      take_screenshot && raise
    end
  
    def wait_for_modal
      synchronize { find('#modal').find('.modal-window') }
    end
  
    def max_wait_time
      MAX_WAIT_TIME
    end
  end