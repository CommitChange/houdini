# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

json.id subtransaction.subtransactable.houid
json.type 'subtransaction'
json.supporter subtransaction.supporter.houid
json.nonprofit subtransaction.nonprofit.houid
json.transaction subtransaction.trx.houid

json.partial! subtransaction.subtransactable, as: :subtransactable

json.payments subtransaction.subtransaction_payments do |py|
	json.partial! py, as: :subtransaction_payment
end
