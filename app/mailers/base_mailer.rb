# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class BaseMailer < ActionMailer::Base
  include Devise::Controllers::UrlHelpers
  add_template_helper(ApplicationHelper)
  default :from => Settings.mailer.default_from
  layout 'email'
end
