# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class MiscRefundInfo < ActiveRecord::Base
  attr_accessible :is_modern,
    :stripe_application_fee_refund_id

  belongs_to :refund
end
