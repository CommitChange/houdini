# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
class StripeTransaction < ApplicationRecord
	include Model::Subtransactable
	setup_houid :stripetrx, :houid
	delegate :created, to: :subtransaction
	delegate :net_amount, to: :subtransaction_payments

	as_money :amount, :net_amount

	# Handle a completed refund from a legacy Refund object
	def process_refund(refund)
		refund = self.subtransaction.subtransaction_payments.create!(paymentable:StripeTransactionRefund.new, subtransaction: subtransaction, legacy_payment: refund.payment, created: refund.payment.date)
		update!(amount: 	subtransaction_payments.gross_amount)
		refund
	end

	def process_dispute_withdrawal(dispute, new_withdrawal)
		dispute_payment = self.subtransaction.subtransaction_payments.create!(paymentable:StripeTransactionDispute.new, subtransaction: subtransaction, legacy_payment: new_withdrawal, created: new_withdrawal.date)
		update!(amount: 	subtransaction_payments.gross_amount)
		dispute_payment
	end

	def process_dispute_reversal(dispute, new_reversal)
		dispute_reversal_payment = self.subtransaction.subtransaction_payments.create!(paymentable:StripeTransactionDisputeReversal.new, subtransaction: subtransaction, legacy_payment: new_reversal, created: new_reversal.date)
		update!(amount: 	subtransaction_payments.gross_amount)
		dispute_reversal_payment
	end

	def publish_created
		#object_events.create( event_type: 'stripe_transaction.created')
	end

	def publish_updated
		#object_events.create( event_type: 'stripe_transaction.updated')
	end

	def publish_deleted
		#object_events.create( event_type: 'stripe_transaction.deleted')
	end
end
