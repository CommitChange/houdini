# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
# rubocop:disable Metrics/BlockLength, Metrics/AbcSize, Metrics/MethodLength
class OfflineTransaction < ApplicationRecord
	include Model::Subtransactable
	delegate :created, to: :subtransaction

	def amount_as_money
		Amount.new(amount || 0, nonprofit.currency)
	end

	def net_amount
		subtransaction_payments.map{|i| i.net_amount}.sum
	end

	def net_amount_as_money
		Amount.new(net_amount || 0, nonprofit.currency)
	end

	concerning :JBuilder do
		included do
			setup_houid :offlinetrx, :houid
		end
	end
end
# rubocop:enable all
