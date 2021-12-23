# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
json.type 'trx_assignment'

json.id transaction_assignment.assignable.houid

json.supporter transaction_assignment.supporter.houid
json.nonprofit transaction_assignment.nonprofit.houid
json.transaction transaction_assignment.trx.houid


json.partial! transaction_assignment.assignable, as: :assignable

