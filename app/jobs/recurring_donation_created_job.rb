# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class RecurringDonationCreatedJob < ApplicationJob
  queue_as :default

  def perform(recurring_donation)
    recurring_donation.supporter&.active_email_lists&.update_member_on_all_lists
  end
end
