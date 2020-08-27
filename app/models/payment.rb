# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
# A payment represents the event where a nonprofit receives money from a supporter
# If connected to a charge, this represents money potentially debited to the nonprofit's account
# If connected to an offsite_payment, this is money the nonprofit is recording for convenience.

class Payment < ActiveRecord::Base
	extend ActiveSupport::Concern


  attr_accessible \
    :towards,
		:gross_amount,
		:refund_total,
		:fee_total,
		:net_amount,
		:kind,
		:date,
		:nonprofit

	belongs_to :supporter
	belongs_to :nonprofit
	has_one :charge
	has_one :offsite_payment
	has_one :refund
	has_one :dispute_transaction
	has_many :disputes, through: :charge
	belongs_to :donation
	has_many :tickets
	has_one :campaign, through: :donation
	has_many :events, through: :tickets
	has_many :payment_payouts
	has_many :charges
	has_one :misc_payment_info
	
	has_many :activities, :as => :attachment do
		def create(attributes=nil, options={}, &block)
			attributes = proxy_association.owner.build_activity_attributes.merge(attributes || {})
			proxy_association.create(attributes, options, &block)
		end

		def build(attributes=nil, options={}, &block)
			attributes = proxy_association.owner.build_activity_attributes.merge(attributes || {})
			proxy_association.build(attributes, options, &block)
		end
	end

	def build_activity_json
		dispute_transaction_payment = self
		dispute = dispute_transaction_payment.dispute_transaction.dispute
		original_payment = dispute.original_payment
		case kind
		when 'Dispute', 'DisputeReversed'
      return {
        gross_amount: dispute_transaction_payment.gross_amount,
        fee_total: dispute_transaction_payment.fee_total,
				net_amount: dispute_transaction_payment.net_amount,
				reason: dispute.reason,
				status: dispute.status,
				original_id: original_payment.id,
				original_kind: original_payment.kind,
				original_gross_amount: original_payment.gross_amount,
				original_date: original_payment.date,
				started_at: dispute.started_at
			}
		end
	end

	def build_activity_attributes
		dispute_transaction_payment = self
		case kind
		when 'Dispute'
      return {
        kind: 'DisputeFundsWithdrawn',
        date: dispute_transaction_payment.date,
        nonprofit: dispute_transaction_payment.nonprofit,
        supporter: dispute_transaction_payment.supporter,
        json_data: build_activity_json
      }
		when 'DisputeReversed'
			return {
				kind: 'DisputeFundsReinstated',
        date: dispute_transaction_payment.date,
        nonprofit: dispute_transaction_payment.nonprofit,
        supporter: dispute_transaction_payment.supporter,
        json_data: build_activity_json
			}
		end
	end
end
