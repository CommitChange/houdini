# frozen_string_literal: true 

# file contains some patches to Rspec system tests and some general config

module BetterCommitChangeRailsSystemTests 
    # Use relative path in screenshot message to make it clickable in VS Code when running in Docker
    def image_path
        Pathname.new(absolute_image_path).relative_path_from(Rails.root).to_s
    end
    
    # this is where Capybara.last_used_session comes in handy
    # the take screenshot method makes failure screenshots with 
    # multi-session setup
    def take_screenshot
        return super unless Capybara.last_used_session
    
        Capybara.using_session(Capybara.last_used_session) { super }
      end
    end

Rspec.configure do |config| 
    config.include BetterCommitChangeRailsSystemTests, type: :system

    # make urls in mailers contain the correct server host
    # you need this info to test links in emails 
    config.around(:each, type: :system) do |ex| 
        was_host = Rails.application.default_url_options[:host]
        Rails.application.default_url_options[:host] = Capybara.server_host
        ex.run
        Rails.application.default_url_options[:host] = was_host 
    end 

    # this hook needs to run before the others
    config.prepend_before(:each, type: :system) do
        #continue to use JS driver
        driven_by Capybara.javascript_driver
    end 
end 