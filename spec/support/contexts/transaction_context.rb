# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

shared_context 'json results for transaction expectations' do

	require_relative '../json_expectations'
	
	def generate_transaction_json(args={})
		JsonExpectations::TransactionExpectation.new(args).output
	end

	def generate_object_event_json(args={})
		JsonExpectations::ObjectEventExpectation.new(args).output
	end

	def generate_payment_json(args={})
		JsonExpectations::PaymentExpectation.new(args).output
	end

end
