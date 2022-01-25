# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
class StripeTransactionRefund < ApplicationRecord
	include Model::SubtransactionPaymentable
  setup_houid :striperef, :houid

	has_one :legacy_payment, class_name: 'Payment', through: :subtransaction_payment

	delegate :gross_amount, :net_amount, :fee_total, to: :legacy_payment
 
	def gross_amount_as_money
		Amount.new(gross_amount || 0, currency)
	end

	def net_amount_as_money
		Amount.new(net_amount || 0, currency)
	end

	def fee_total_as_money
		Amount.new(fee_total || 0, currency)
	end

	def created
		legacy_payment.date
	end


	def stripe_id
		legacy_payment.refund.stripe_refund_id
	end

	def publish_created
		object_events.create( event_type: 'stripe_transaction_refund.created')
	end

	def publish_updated
		object_events.create( event_type: 'stripe_transaction_refund.updated')
	end

	def publish_deleted
		object_events.create( event_type: 'stripe_transaction_refund.deleted')
	end

end