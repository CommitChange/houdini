# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

RSpec.describe ApiNew::TransactionsController, type: :request do
	around do |ex|
		Timecop.freeze(2020, 5, 4) do
			ex.run
		end
	end

	let(:nonprofit) { transaction_for_donation.nonprofit }
	let(:user) { create(:user) }
	let(:supporter) { transaction_for_donation.supporter }

	let(:transaction_for_donation) do
		create(:transaction_for_donation)
	end

	before do
		transaction_for_donation
	end

	def index_base_path(nonprofit_id)
		"/api_new/nonprofits/#{nonprofit_id}/transactions"
	end

	def index_base_url(nonprofit_id, _event_id)
		"http://www.example.com#{index_base_path(nonprofit_id)}"
	end

	describe 'GET /' do
		context 'with nonprofit user' do
			subject(:json) do
				response.body
			end

			before do
				user.roles.create(name: 'nonprofit_associate', host: nonprofit)
				sign_in user
				get index_base_path(nonprofit.houid)
			end

			it {
				expect(response).to have_http_status(:success)
			}

			# it { expect(json['data'].count).to eq 1 }

			describe 'for transaction_for_donation' do
				# subject(:first) do
				# 	json['data'].first
				# end

				# let(:item) {
				# 	first
				# }

				def base_path(nonprofit_id, transaction_id)
					index_base_path(nonprofit_id) + "/#{transaction_id}"
				end

				let(:transaction) { transaction_for_donation }

				def base_url(nonprofit_id, transaction_id)
					"http://www.example.com#{base_path(nonprofit_id, transaction_id)}"
				end
				include_context 'with json results for transaction_for_donation'
				it {
					is_expected.to include_json(
						first_page: true, 
						last_page: true, 
						current_page: 1,
						requested_size: 25, 
						total_count: 1,
						data: [generate_transaction_for_donation_json]
						
				)}
			end

		end

		context 'with no user' do
			it 'returns unauthorized' do
				get index_base_path(nonprofit.houid)
				expect(response).to have_http_status(:unauthorized)
			end
		end
	end

	describe 'GET /:transaction_id' do
		def show_base_path(nonprofit_id, transaction_id)
			index_base_path(nonprofit_id) + "/" + transaction_id
		end

		context 'with nonprofit user' do
			subject(:json) do
				response.body
			end

			before do
				user.roles.create(name: 'nonprofit_associate', host: nonprofit)
				sign_in user
				get show_base_path(nonprofit.houid, transaction_for_donation.houid)
			end

			it {
				expect(response).to have_http_status(:success)
			}
			include_context 'with json results for transaction_for_donation' do 
				let(:transaction) {transaction_for_donation}
			end			

			it {
				is_expected.to include_json(generate_transaction_for_donation_json)
			}
		end

		context 'with no user' do
			it 'returns unauthorized' do
				get show_base_path(nonprofit.id, transaction_for_donation.houid)
				expect(response).to have_http_status(:unauthorized)
			end
		end
	end
end
