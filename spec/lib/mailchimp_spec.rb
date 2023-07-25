# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

describe Mailchimp do
	let(:np) { force_create(:nonprofit)}
		let(:user) {force_create(:user)}
		let(:tag_master) {force_create(:tag_master, nonprofit: np)}
		let(:email_list) {force_create(:email_list, mailchimp_list_id: 'list_id', tag_master: tag_master, nonprofit:np, list_name: "temp")}
		let(:drip_email_list) {force_create(:drip_email_list, nonprofit: np, user: user)}
		let(:supporter_on_both) { force_create(:supporter, nonprofit:np, email: 'on_BOTH@email.com', name: nil)}
		let(:supporter_on_local) { force_create(:supporter, nonprofit:np, email: 'on_local@email.com', name: 'Penelope Rebecca Schultz')}
		let(:tag_join) {force_create(:tag_join, tag_master: tag_master, supporter: supporter_on_both)}
		let(:tag_join2) {force_create(:tag_join, tag_master: tag_master, supporter: supporter_on_local)}
	
		let(:active_recurring_donation_1) {force_create(:recurring_donation_base, supporter_id: supporter_on_local.id, start_date: Time.new(2019, 10,12))}
		let(:cancelled_recurring_donation_1) {force_create(:recurring_donation_base, supporter_id: supporter_on_local.id, start_date: Time.new(2020,1, 12), active:false)}
		let(:active_recurring_donation_2) {force_create(:recurring_donation_base, supporter_id: supporter_on_local.id, start_date: Time.new(2019, 11, 12))}

	describe '.hard_sync_list' do
		let(:ret_val) { [{id: 'on_both', email_address: 'on_both@email.com', 
			merge_fields: {
				F_NAME: 'Penelope Rebecca',
				L_NAME: 'Schultz'
		}
		},
		{id: 'on_mailchimp', email_address: 'on_mailchimp@email.com', 
		merge_fields: {
			F_NAME: 'Penelope Rebecca',
			L_NAME: 'Schultz',
			RD_URL_1: active_recurring_donation_2,
			RD_URL_2: active_recurring_donation_1,
		}}
		]
		}

		it 'excepts when excepting' do
			expect(Mailchimp).to receive(:get_list_mailchimp_subscribers).with(email_list).and_raise

			expect{ Mailchimp.generate_batch_ops_for_hard_sync(email_list)}.to raise_error
		end

		it 'passes without delete' do
			tag_join
			tag_join2
			email_list
			active_recurring_donation_1
			active_recurring_donation_2
			cancelled_recurring_donation_1

			expect(Mailchimp).to receive(:get_list_mailchimp_subscribers).with(email_list).and_return(ret_val)

			result = Mailchimp.generate_batch_ops_for_hard_sync(email_list)


			expect(result).to match( 
				[{
					method: 'POST', 
					path: 'lists/list_id/members', 
					body: an_instance_of(String)
				}])
    end

		it 'passes with delete' do
			tag_join
			tag_join2
			email_list

			expect(Mailchimp).to receive(:get_list_mailchimp_subscribers).with(email_list).and_return(ret_val)

			result = Mailchimp.generate_batch_ops_for_hard_sync(email_list, true)
			expect(result).to match([
														{
																method: 'POST',
																path: 'lists/list_id/members',
																body: an_instance_of(String)
														},
														{
															method: 'DELETE',
															path: 'lists/list_id/members/on_mailchimp'
														}								
													])
		end
  end

	describe '.create_nonprofit_user_subscribe_body' do 
		let(:nonprofit) { create(:nonprofit)}

		it 'creates nonprofit user subscriber' do 
			expect(Mailchimp.create_nonprofit_user_subscribe_body(nonprofit, user)).to match({
				'email_address' => user.email,
				'status' => 'subscribed',
				'merge_fields' => {
					'NONPROFIT_ID' => nonprofit.id
				}
			})
		end 

	end 

	describe '.create_subscribe_body' do

		describe 'names' do
			it 'has provides the F_NAME and L_NAME when there' do
				expect(Mailchimp.create_subscribe_body(supporter_on_local)).to match({
					'email_address' =>   supporter_on_local.email, 
					'status' => 'subscribed',
					'merge_fields' =>  {
						'F_NAME' => "Penelope Rebecca",
						'L_NAME' => "Schultz"
					}
				
				})
			end

			it 'provides null F_NAME and L_NAME when not there' do
				expect(Mailchimp.create_subscribe_body(supporter_on_both)).to match({
					'email_address' =>   supporter_on_both.email, 
					'status' => 'subscribed',
					'merge_fields' =>  {
						'F_NAME' => nil,
						'L_NAME' => nil,
					}
				})
			end
		end

		describe 'recurring donation urls' do

			it 'adds a single RD_URL when theres a single active RD' do
				active_recurring_donation_1
				cancelled_recurring_donation_1
				expect(Mailchimp.create_subscribe_body(supporter_on_local)).to match( {
					'email_address' =>   supporter_on_local.email, 
					'status' => 'subscribed',
					'merge_fields' =>  {
						'F_NAME' => "Penelope Rebecca",
						'L_NAME' => "Schultz",
						'RD_URL_1' => an_instance_of(String).and(ending_with("recurring_donations/#{active_recurring_donation_1.id}/edit?t=#{active_recurring_donation_1.edit_token}")),
					}
				
				})
			end

			it 'adds a second RD_URL when theres a second active RD' do
				active_recurring_donation_1
				active_recurring_donation_2
				cancelled_recurring_donation_1
				expect(Mailchimp.create_subscribe_body(supporter_on_local)).to match({
					'email_address' =>   supporter_on_local.email, 
					'status' => 'subscribed',
					'merge_fields' =>  {
						'F_NAME' => "Penelope Rebecca",
						'L_NAME' => "Schultz",
						'RD_URL_1' => an_instance_of(String).and(ending_with("recurring_donations/#{active_recurring_donation_2.id}/edit?t=#{active_recurring_donation_2.edit_token}")),
						'RD_URL_2' => an_instance_of(String).and(ending_with("recurring_donations/#{active_recurring_donation_1.id}/edit?t=#{active_recurring_donation_1.edit_token}"))
					}
				
				})
			end
			
		end
	end

	describe '.get_emails_for_supporter_ids' do
		let(:nonprofit) { create(:nonprofit)}
		it 'does not include emails for supporters with nil as email' do
			supporter = create(:supporter, nonprofit: nonprofit, email: nil)
			expect(Mailchimp.get_emails_for_supporter_ids(nonprofit.id, supporter.id)).to be_empty
		end

		it 'does not include emails for supporters with zero length string as email' do
			supporter = create(:supporter, nonprofit: nonprofit, email: '')
			expect(Mailchimp.get_emails_for_supporter_ids(nonprofit.id, supporter.id)).to be_empty
		end

		it 'does not include emails for supporters with blank string as email' do
			supporter = create(:supporter, nonprofit: nonprofit, email: '   ')
			expect(Mailchimp.get_emails_for_supporter_ids(nonprofit.id, supporter.id)).to be_empty
		end

		it 'includes email for supporter with email' do
			supporter = create(:supporter, nonprofit: nonprofit, email: 'an@email.com')
			expect(Mailchimp.get_emails_for_supporter_ids(nonprofit.id, supporter.id)).to eq ['an@email.com']
		end
	end
end
