# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
class StripeTransaction < ApplicationRecord
	include Model::Subtransactable
	setup_houid :stripetrx, :houid
	delegate :created, to: :subtransaction

	as_money :amount, :net_amount

	def net_amount
		subtransaction_payments.map{|i| i.net_amount}.sum
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
