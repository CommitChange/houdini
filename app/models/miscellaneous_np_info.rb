# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class MiscellaneousNpInfo < ActiveRecord::Base

  attr_accessible \
  :donate_again_url,
  :change_amount_message,
  :hide_cover_fees

  belongs_to :nonprofit
end
