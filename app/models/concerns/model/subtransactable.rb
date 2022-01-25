# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
module Model::Subtransactable
	extend ActiveSupport::Concern

	included do
		include Model::Houidable

		has_one :subtransaction, as: :subtransactable, dependent: :nullify
		has_one :trx, through: :subtransaction, class_name: 'Transaction'
		has_one :supporter, through: :trx
		has_one :nonprofit, through: :trx

		has_many :subtransaction_payments, through: :subtransaction

		delegate :currency, to: :nonprofit
	end
end
