# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

# rubocop:disable Metrics/BlockLength, Metrics/AbcSize
class OfflineTransactionCharge < ApplicationRecord
	include Model::SubtransactionPaymentable
	belongs_to :payment

	delegate :gross_amount, :net_amount, :fee_total, to: :payment
	delegate :currency, to: :nonprofit

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
		payment.date
	end

	concerning :JBuilder do
		included do
			setup_houid :offtrxchrg, :houid
		end
	end
end
# rubocop:enable all
