# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
json.type 'payment'

json.id subtransaction_payment.paymentable.houid
json.created subtransaction_payment.paymentable.created.to_i

json.supporter subtransaction_payment.supporter.houid
json.nonprofit subtransaction_payment.nonprofit.houid
json.transaction subtransaction_payment.trx.houid

json.subtransaction subtransaction_payment.subtransaction.subtransactable.houid

json.partial! subtransaction_payment.paymentable, as: :paymentable
