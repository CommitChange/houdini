# frozen_string_literal: true

# file contains some patches to Rspec system tests and some general config

module BetterRailsSystemTests
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
