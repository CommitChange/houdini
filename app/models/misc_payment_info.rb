# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class MiscPaymentInfo < ActiveRecord::Base
  belongs_to :payment
  attr_accessible :fee_covered
end
