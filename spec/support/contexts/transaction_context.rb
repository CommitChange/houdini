# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

shared_context 'with json results for transaction_for_donation' do

	let(:expected_fees) { -300}

	around do |ex|
		Timecop.freeze(2020, 5, 4) do
			ex.run
		end
	end


	def generate_transaction_for_donation_json
		{
			'object' => 'transaction',
			'id' => transaction.houid,
			'created' => Time.current.to_i,
			'amount' => {
				'cents' => 4000,
				'currency' => 'usd'
			},
			'nonprofit' => nonprofit.houid,
			supporter: {
				id: supporter.houid
			},
			subtransaction: {
				'id' => match_houid(subtransaction_houid),
				'type' => 'subtransaction',
				'object' => subtransaction_object,
				supporter: supporter.houid,
				nonprofit: nonprofit.houid,
				transaction: transaction.houid,
				'created' => Time.current.to_i,
				'amount' => {
					'cents' => 4000,
					'currency' => 'usd'
				},
				'net_amount' => {
					'cents' => 4000+expected_fees,
					'currency' => 'usd'
				},
				payments: [
					{
						supporter: supporter.houid,
						nonprofit: nonprofit.houid,
						'created' => Time.current.to_i,
						transaction: transaction.houid,
						subtransaction: match_houid(subtransaction_houid),
						'fee_total' => {
							'cents' => expected_fees,
							'currency' => 'usd'
						},
						'gross_amount' => {
							'cents' => 4000,
							'currency' => 'usd'
						},
						'net_amount' => {
							'cents' => 4000+expected_fees,
							'currency' => 'usd'
						},
						'id' => match_houid(charge_houid),
						type: 'payment'
					}
				]
			},
			payments:  [
				{
					supporter: supporter.houid,
					nonprofit: nonprofit.houid,
					'created' => Time.current.to_i,
					transaction: transaction.houid,
					subtransaction: match_houid(subtransaction_houid),
					'fee_total' => {
						'cents' => expected_fees,
						'currency' => 'usd'
					},
					'gross_amount' => {
						'cents' => 4000,
						'currency' => 'usd'
					},
					'net_amount' => {
						'cents' => 4000+expected_fees,
						'currency' => 'usd'
					},
					'id' => match_houid(charge_houid),
					type: 'payment'
				}
			],
			transaction_assignments: [
				{
					'type' => 'trx_assignment',
					supporter: supporter.houid,
					nonprofit: nonprofit.houid,
					transaction: transaction.houid,
					'object' => 'donation',
					'amount' => {
						'cents' => 4000,
						'currency' => 'usd'
					},
					'designation'=> nil,
					id: match_houid('don')
				}
			]
		}
	end
end
