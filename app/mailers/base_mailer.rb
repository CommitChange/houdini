# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class BaseMailer < ApplicationMailer
  include Devise::Controllers::UrlHelpers
  helper ApplicationHelper
  default :from => Settings.mailer.default_from, "X-SES-CONFIGURATION-SET" => "Admin"
  layout "email"
end
