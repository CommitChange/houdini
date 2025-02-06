# frozen_string_literal: true 

# this configuration file assumes that a user wants to use a locally installed Chrome 
# if CHROME_URL is not set or if the browser is not responding. 

remote_chrome_url = ENV["CHROME_URL"]

# Cannot connect Chrome CDP by hostnames (other than localhost)
# Chrome CDP does allow use of IP addresses
if remote_chrome_url&.match?(/host.docker.internal/)
    require "resolv"
  
    uri = URI.parse(remote_chrome_url)
    ip = Resolv.getaddress(uri.host)
  
    remote_chrome_url = remote_chrome_url.sub("host.docker.internal", ip)
  end
  
  REMOTE_CHROME_URL = remote_chrome_url
  REMOTE_CHROME_HOST, REMOTE_CHROME_PORT =
    if REMOTE_CHROME_URL
      URI.parse(REMOTE_CHROME_URL).yield_self do |uri|
        [uri.host, uri.port]
      end
    end
  
  # Check whether the remote chrome is running and configure the Capybara
  # driver for it.
  remote_chrome =
    begin
      if REMOTE_CHROME_URL.nil?
        false
      else
        Socket.tcp(REMOTE_CHROME_HOST, REMOTE_CHROME_PORT, connect_timeout: 1).close
        true
      end
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
      false
    end
  
  remote_options = remote_chrome ? {url: REMOTE_CHROME_URL} : {}


# load Cuprite Capybara integration
require "capybara/cuprite"

# Register our driver to be able to use it later 
# NOTE: The name :cuprite is already registered by Rails.
# See https://github.com/rubycdp/cuprite/issues/180

Capybara.register_driver(:cc_duprite) do |app| 
    Capybara::Cuprite::Driver.new(
        app,
        ** {
            window_size: [1200, 800],
            # See additional options for Dockerized environment in the respective section of this article
            browser_options: remote_chrome ? {"no-sandbox" => nil } : {},
            # Increase Chrome startup wait time (required for stable CI builds)
            process_timeout: 10,
            # Enable debugging capabilities
            inspector: true
        }.merge(remote_options)
    )
end 

# configure Capybara to use :cc_duprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :cc_duprite

# add shortcuts for cuprite-specific debugging helpers
module CupriteHelpers
    # Drop #pause anywhere in a test to stop the execution.
    def pause
      page.driver.pause
    end
  
    # Drop #debug anywhere in a test to open a Chrome inspector and pause the execution
    # this debug helper will print Debug Viewer URL instead of opening a browser
    def debug(binding = nil)
        $stdout.puts "Open Chrome inspector at http://localhost:3333"
        return binding.break if binding
      
        page.driver.pause
    end
  end
  
  RSpec.configure do |config|
    config.include CupriteHelpers, type: :system
  end