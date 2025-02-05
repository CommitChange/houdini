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

    # delegate :driver, :document, to: :page, prefix: false
    # delegate :wait_for_network_idle, to: :driver, prefix: false
    # delegate :synchronize, to: :document, prefix: false
  end
end
