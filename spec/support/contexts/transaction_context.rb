# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

shared_examples 'an example with a single payment' do
	describe 'payments' do 
		subject(:payments) {
			parent_object['payments']
		}

		it {
			is_expected.to be_one
		}

		describe 'first payment' do
			subject(:first_payment) { payments.first}
			it {
				is_expected.to include('type' => 'payment')
			}

			it {
				is_expected.to include('id' => match_houid('offtrxchrg'))
			}

			it {
				is_expected.to include('gross_amount' => {
					'cents' => 4000,
					'currency' => 'usd'
				})
			}

			it {
				is_expected.to include('net_amount' => {
					'cents' => 4000-expected_fees,
					'currency' => 'usd'
				})
			}

			it {
				is_expected.to include('fee_total' => {
					'cents' => expected_fees,
					'currency' => 'usd'
				})
			}

			it {
				is_expected.to include('supporter' => match_houid('supp'))
			}

			it {
				is_expected.to include('nonprofit' => match_houid('np'))
			}

			it {
				is_expected.to include('transaction' => match_houid('trx'))
			}

			it {
				is_expected.to include('subtransaction' => match_houid('offlinetrx'))
			}
		end
	end
end

shared_context 'with json results for transaction_for_donation' do

	let(:expected_fees) { 300}

	around do |ex|
		Timecop.freeze(2020, 5, 4) do
			ex.run
		end
	end

	

	it {
		is_expected.to include('object' => 'transaction')
	}

	it {
		is_expected.to include('id' => transaction.houid)
	}

	it {
		is_expected.to include('created' => Time.current.to_i)
	}

	it {
		is_expected.to include(
			'amount' => {
				'cents' => 4000,
				'currency' => 'usd'
			}
		)

	}

	it {
		is_expected.to include('nonprofit' => nonprofit.houid)
	}

	describe 'supporter' do
		subject(:supporter_obj) { parent_object['supporter']}
		it {
			is_expected.to include('id' => supporter.houid)
		}
	end

	describe 'subtransaction' do 
		subject(:subtrx) {item['subtransaction']}

		it {
			is_expected.to include('id' => match_houid('offlinetrx'))
		}
		it {
			is_expected.to include('type' => 'subtransaction')
		}
		it {
			is_expected.to include(
					'object' => 'offline_transaction')
		}
		it {
			is_expected.to include(
			'supporter' => match_houid('supp'))
		}
		it {
			is_expected.to include(
			'nonprofit' => match_houid('np'))
		}
		it {
			is_expected.to include(
			'created' => Time.current.to_i)
		}
		it {
			is_expected.to include(
			'transaction' => match_houid('trx'))
		}
		it {
			is_expected.to include(
			'amount' => {
				'cents' => 4000,
				'currency' => 'usd'
			})
		}
		it {
			is_expected.to include(
			'net_amount' => {
				'cents' => 4000-expected_fees,
				'currency' => 'usd'
			})
		}

		let(:parent_object) {subtrx}

		it_behaves_like 'an example with a single payment'

		
	end

	let(:parent_object) { item}
	
	it_behaves_like 'an example with a single payment'
	


	describe 'transaction_assignments' do 
		subject(:transaction_assignments) {parent_object['transaction_assignments']}
		it { is_expected.to be_one}

		describe 'first assignment' do
			subject(:first_trx_assign) {transaction_assignments.first}

			it {
				is_expected.to include('type' => 'trx_assignment')
			}

			it {
				is_expected.to include('object' => 'donation')
			}

			it {
				is_expected.to include('supporter' => supporter.houid)
			}
			
			it {
				is_expected.to include('nonprofit' => nonprofit.houid)
			}

			it {
				is_expected.to include('transaction' => transaction.houid)
			}

			it {
				is_expected.to include('amount' => {
					'cents' => 4000,
					'currency' => 'usd'
				})
			}
			
			it {
				is_expected.to include('designation'=> nil)
			}
		end
	end
	# it {
	# 	is_expected.to include('url' =>
	# 		base_url(nonprofit.houid, transaction.houid))
	# }
end
