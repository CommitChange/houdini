# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
json.id transaction.houid

json.object 'transaction'

json.supporter do 
	json.partial! transaction.supporter, as: :supporter
end

json.nonprofit transaction.nonprofit.houid

json.created transaction.created.to_i

json.amount do
	json.partial! '/api_new/common/amount', amount: transaction.amount_as_money
end

json.subtransaction do 
	json.partial! transaction&.subtransaction, as: :subtransaction
end

json.transaction_assignments transaction.transaction_assignments do |tra|
	json.partial!  tra, as: :transaction_assignment
end

json.payments transaction.subtransaction_payments do |subt_p|
	json.partial! subt_p, as: :subtransaction_payment
end

#json.url api_nonprofit_transaction_url(transaction.nonprofit, transaction)
