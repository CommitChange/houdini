# frozen_string_literal: true 

# Base class  for system tests

Dir[File.join(__dir__, "system/support/**/*.rb")].sort.each { |file| require file }