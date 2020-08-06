# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class Dispute < ActiveRecord::Base

  Reasons = [:unrecognized, :duplicate, :fraudulent, :subscription_canceled, :product_unacceptable, :product_not_received, :unrecognized, :credit_not_processed, :goods_services_returned_or_refused, :goods_services_cancelled, :incorrect_account_details, :insufficient_funds, :bank_cannot_process, :debit_not_authorized, :general]

  Statuses = [:needs_response, :under_review, :won, :lost, :lost_and_paid]

  attr_accessible \
    :gross_amount, # int
    :charge_id, :charge,
    :payment_id, :payment,
    :status,
    :reason

  belongs_to :charge
  belongs_to :payment
  has_one :stripe_dispute, foreign_key: :stripe_dispute_id, primary_key: :stripe_dispute_id
  has_many :dispute_transactions

end

