# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class MailchimpSignupJob < ApplicationJob
  queue_as :default

  def perform(email, mailchimp_list_id)
    Mailchimp.signup(email, mailchimp_list_id)
  end
end
