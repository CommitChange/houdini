# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

RSpec.describe Nonprofits::WidgetsController, type: :controller do

  describe "GET #show" do

    context "when an invalid type is provided" do
      it 'renders bad request' do
         get :show, {type: 'fake_type', nonprofit_id: "1"}

         expect(response).to have_http_status(:bad_request)
      end
    end

    context "when an invalid nonprofit is provided" do 
      it 'raises RecordNotFound' do
        expect { get :show, {type: 'campaign_thermometer', nonprofit_id: "1"}}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when a valid nonprofit but no campaign is provided" do
      it 'raises :RecordNotFound' do
        expect { get :show, {type: 'campaign_thermometer', nonprofit_id: create(:nonprofit).id}}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when a valid nonprofit but invalid campaign is provided" do
      it 'raises RecordNotFound' do
        expect { get :show, {type: 'campaign_thermometer', nonprofit_id: create(:nonprofit).id, campaign_id: "4321541325"}}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when a valid nonprofit and campaign are provided" do

      it "returns http success" do
        campaign = create(:campaign_with_things_set_1)
        get :show, {type:'campaign_thermometer', nonprofit_id: campaign.nonprofit.id, campaign_id: campaign.id}
        expect(response).to have_http_status(:success)
      end
    end
  end

end
