# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class Refund < ApplicationRecord
  Reasons = [:duplicate, :fraudulent, :requested_by_customer]

  attr_accessor :failure_message

  belongs_to :charge
  belongs_to :payment
  has_one :subtransaction_payment, through: :payment
  has_one :misc_refund_info
  has_one :nonprofit, through: :charge
  has_one :supporter, through: :charge

  scope :not_disbursed, -> { where(disbursed: [nil, false]) }
  scope :disbursed, -> { where(disbursed: [true]) }

  has_many :manual_balance_adjustments, as: :entity

  def original_payment
    charge&.payment
  end

  def from_donation?
    !!original_payment&.donation
  end
end
