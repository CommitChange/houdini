# frozen_string_literal: true 

# this file covers Capybara settings (not already covered by Rails system tests)
Capybara.server_host = "0.0.0.0"
Capybara.server_port = 3001
Capybara.app_host = "http://#{ENV.fetch("APP_HOST", 'hostname'.strip&.downcase || "0.0.0.0")}"

#  With Cuprite, there is no need for waiting long
# We use a Capybara default value here explicitly.
Capybara.default_max_wait_time = 2

# Normalize whitespaces when using `has_text?` and similar matchers,
Capybara.default_normalize_ws = true

# Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
Capybara.save_path = ENV.fetch("CAPYBARA_ARTIFACTS", "./tmp/capybara")

Capybara.singleton_class.prepend(Module.new do
    attr_accessor :last_used_session
    
    # using session allows you to manipluate a diff browser session
    # this patch tracks the name of the last session used. 
    def using_session(name, &block)
      self.last_used_session = name
      super
    ensure
      self.last_used_session = nil
    end
  end)