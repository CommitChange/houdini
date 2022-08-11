# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class MiscRecurringDonationInfo < ActiveRecord::Base
  belongs_to :recurring_donation
  attr_accessible :fee_covered
end
