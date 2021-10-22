# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

describe QueryDonations do

  describe 'campaign_export' do
    let(:nonprofit) {force_create(:nonprofit)}
    let(:supporter) {force_create(:supporter, :with_primary_address)}

    let(:profile_email) {  'something@profile_email.com'}
    let(:profile) do
      u = force_create(:user, email: profile_email)
      profile = force_create(:profile, user: u)
    end
    let(:campaign) {force_create(:campaign, nonprofit:nonprofit, show_total_count:false, show_total_raised: false, goal_amount: 16000, profile: profile)}

    let(:profile_email1) {  'something1@profile_email.com'}
    let(:profile1) {
      u = force_create(:user, email: profile_email1)
      profile = force_create(:profile, user: u)
    }
    let(:campaign_child) {force_create(:campaign, nonprofit:nonprofit, parent_campaign:campaign, show_total_count:true, show_total_raised: true, goal_amount: 8000, profile: profile1)}

    let(:profile_email2) {  'something2@profile_email.com'}
    let(:profile2) {
      u = force_create(:user, email: profile_email2)
      profile = force_create(:profile, user: u)
    }
    let(:campaign_child_2) {force_create(:campaign, nonprofit:nonprofit, parent_campaign:campaign, show_total_count:true, show_total_raised: true, goal_amount: 4000, profile: profile2 )}

    let(:donation) { force_create(:donation, campaign: campaign, amount: 1000, supporter:supporter)}
    let(:payment) { force_create(:payment, donation: donation, gross_amount:1000, supporter:supporter)}

    let(:donation2) { force_create(:donation, campaign: campaign, amount: 2000, supporter:supporter)}
    let(:payment2) { force_create(:payment, donation: donation2, gross_amount:2000, supporter:supporter)}

    let(:donation3) { force_create(:donation, campaign: campaign_child, amount: 2000, supporter:supporter)}
    let(:payment3) { force_create(:payment, donation: donation3, gross_amount:4000, kind:'RecurringPayment', supporter:supporter)}
    let(:payment3_1) { force_create(:payment, donation: donation3, gross_amount:2000, kind:'RecurringPayment', supporter:supporter)}
    let(:recurring) {force_create(:recurring_donation, donation: donation3, amount: 2000, supporter:supporter)}

    let(:donation4) { force_create(:donation, campaign: campaign_child_2, amount: 8000, supporter:supporter)}
    let(:payment4) { force_create(:payment, donation: donation4, gross_amount:8000, supporter:supporter)}

    let(:payments) do
      payment
      payment2
      payment3
      payment3_1
      recurring
      payment4
    end

    let (:campaign_export) do
      payments
      QueryDonations.campaign_export(campaign.id)

    end

    it 'payment amounts get the first payment, not additional ones' do
      export = vector_to_hash(campaign_export)

      expect(export.map{|i| i['Amount']}).to match_array(['$10.00', '$20.00', '$40.00', '$80.00'])
    end

     it 'includes the campaign ids' do
       export = vector_to_hash(campaign_export)
       expect(export.map{|i| i['Campaign Id']}).to match_array([campaign.id, campaign.id, campaign_child.id, campaign_child_2.id])
     end

    it 'includes user email' do
      export = vector_to_hash(campaign_export)
      expect(export.map{|i| i['Campaign Creator Email']}).to match_array([profile_email, profile_email, profile_email1, profile_email2])
    end

    # we need to remove this context when we remove the address attributes from supporters table
    context 'when looking at the supporter address' do
      before do
        supporter.save!

        # Update directly on the database to avoid updating primary_address
        Qx.update(:supporters)
          .set(address: 'Some street', city: 'Aguas Claras', country: 'Brazil', state_code: 'DF', zip_code: '4002-8922')
          .where(id: supporter.id)
          .execute
      end

      it 'points to the primary_address.address instead of the supporter address' do
        result = campaign_export
        address_index = result.first.find_index('Address')
        expect(result.second[address_index]).to eq('That street right there')
      end
      
      it 'address from the supporter does not change' do
        expect(supporter.reload.attributes['address']).to eq('Some street')
      end

      it 'points to the primary_address.city instead of the supporter city' do
        result = campaign_export
        city_index = result.first.find_index('City')
        expect(result.second[city_index]).to eq('Appleton')
      end

      it 'city from the supporter does not change' do
        expect(supporter.reload.attributes['city']).to eq('Aguas Claras')
      end

      it 'points to the primary_address.country instead of the supporter country' do
        result = campaign_export
        country_index = result.first.find_index('Country')
        expect(result.second[country_index]).to eq('United States')
      end
      
      it 'country from the supporter does not change' do
        expect(supporter.reload.attributes['country']).to eq('Brazil')
      end

      it 'points to the primary_address.state_code instead of the supporter state_code' do
        result = campaign_export
        state_code_index = result.first.find_index('State')
        expect(result.second[state_code_index]).to eq('WI')
      end

      it 'state_code from the supporter does not change' do
        expect(supporter.reload.attributes['state_code']).to eq('DF')
      end

      it 'points to the primary_address.zip_code instead of the supporter zip_code' do
        result = campaign_export
        zip_code_index = result.first.find_index('Postal Code')
        expect(result.second[zip_code_index]).to eq('71707273')
      end

      it 'zip_code from the supporter does not change' do
        expect(supporter.reload.attributes['zip_code']).to eq('4002-8922')
      end
    end
  end

  ## move to common area
  def vector_to_hash(vecs)
    keys = vecs.first.to_a.map{|k| k.to_s.titleize}

    vecs.drop(1).map{|v| keys.zip(v).to_h}
  end

end
