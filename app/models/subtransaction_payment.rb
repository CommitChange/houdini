# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
class SubtransactionPayment < ApplicationRecord
	include Model::CreatedTimeable


	belongs_to :subtransaction
	has_one :trx, class_name: 'Transaction', foreign_key: 'transaction_id', through: :subtransaction
	has_one :supporter, through: :subtransaction
	has_one :nonprofit, through: :subtransaction
	belongs_to :legacy_payment, class_name: 'Payment'

	delegated_type :paymentable, types: %w[
		OfflineTransactionCharge
		OfflineTransactionDispute
		OfflineTransactionRefund
		StripeTransactionCharge
		StripeTransactionRefund
		StripeTransactionDispute
		StripeTransactionDisputeReversal
	]

	delegate :gross_amount, :fee_total, :net_amount, :publish_created, :publish_updated, :publish_deleted, :to_houid, to: :paymentable

end
