# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

json.id subtransaction.subtransactable.houid
json.type 'subtransaction'
json.supporter subtransaction.supporter.houid
json.nonprofit subtransaction.nonprofit.houid
json.transaction subtransaction.trx.houid
json.created subtransaction.created.to_i

json.partial! subtransaction.subtransactable, as: :subtransactable, __expand: __expand

handle_array_expansion(:payments, subtransaction.subtransaction_payments, {json:json, __expand: __expand, item_as: :subtransaction_payment}) do |py, opts|
	handle_item_expansion(py, opts)
end
