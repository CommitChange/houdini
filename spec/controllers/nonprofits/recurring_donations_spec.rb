# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"
require "controllers/support/shared_user_context"

describe Nonprofits::RecurringDonationsController, type: :controller do
  include_context :shared_user_context
  describe "rejects unauthenticated users" do
    describe "index" do
      include_context :open_to_np_associate, :get, :index, nonprofit_id: :__our_np, without_json_view: true
    end

    describe "export" do
      include_context :open_to_np_associate, :post, :export, nonprofit_id: :__our_np
    end

    describe "show" do
      include_context :open_to_np_associate, :get, :show, nonprofit_id: :__our_np, id: "1", with_status: 200
    end

    describe "destroy" do
      include_context :open_to_np_associate, :delete, :destroy, nonprofit_id: :__our_np, id: "1"
    end

    describe "update" do
      include_context :open_to_np_associate, :put, :update, nonprofit_id: :__our_np, id: "1"
    end
  end

  describe "open for all" do
    describe "create" do
      include_context :open_to_all, :post, :create, nonprofit_id: :__our_np
    end
  end

  describe "insecure direct object reference protection" do
    let(:other_np_supporter) { create(:supporter, nonprofit: other_nonprofit) }
    let(:other_np_donation) {
      create(:donation,
        supporter: other_np_supporter,
        nonprofit: other_nonprofit,
        amount: 1000)
    }
    let(:other_np_recurring_donation) {
      create(:recurring_donation_base,
        donation: other_np_donation,
        nonprofit: other_nonprofit,
        amount: 1000)
    }

    describe "destroy" do
      it "prevents admin from cancelling recurring donation belonging to another nonprofit" do
        sign_in user_as_np_admin
        expect do
          delete :destroy, params: {nonprofit_id: nonprofit.id,
                                    id: other_np_recurring_donation.id}
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "destroy happy path" do
    let!(:automated_user) { create(:automated_user) }
    let(:supporter) { create(:supporter, nonprofit: nonprofit) }
    let(:donation) {
      create(:donation,
        supporter: supporter,
        nonprofit: nonprofit,
        amount: 1000)
    }
    let(:recurring_donation) {
      create(:recurring_donation_base,
        donation: donation,
        nonprofit: nonprofit,
        supporter_id: supporter.id,
        amount: 1000,
        active: true)
    }

    it "cancels recurring donation and returns updated state" do
      sign_in user_as_np_admin
      expect(recurring_donation.active).to be true

      delete :destroy, params: {nonprofit_id: nonprofit.id,
                                id: recurring_donation.id}

      expect(response).to have_http_status(:ok)

      recurring_donation.reload
      expect(recurring_donation.active).to be false
      expect(recurring_donation.cancelled_by).to eq(user_as_np_admin.email)
      expect(recurring_donation.cancelled_at).to be_present

      response_body = JSON.parse(response.body)
      expect(response_body["active"]).to be false
      expect(response_body["cancelled_by"]).to eq(user_as_np_admin.email)
    end
  end

  describe "Slipflow's recurring donation" do
    render_views

    let!(:automated_user) { create(:automated_user) }
    let(:rd) { create_slipflow_recurring_donation(nonprofit: nonprofit, n_failures: 3) }

    before { sign_in user_as_np_admin }

    it "says so" do
      get :show, params: {nonprofit_id: nonprofit.id, id: rd.id}, format: :json

      expect(JSON.parse(response.body)["data"]["slipflow"]).to eq(true)
    end

    it "refuses an edit" do
      put :update, params: {nonprofit_id: nonprofit.id, id: rd.id, recurring_donation: {donation: {dollars: "20"}, n_failures: 0}}

      expect(response).to have_http_status(:unprocessable_entity)
      expect([rd.reload.amount, rd.n_failures]).to eq([1000, 3])
    end

    it "cancels" do
      delete :destroy, params: {nonprofit_id: nonprofit.id, id: rd.id}

      expect(rd.reload.active).to eq(false)
    end
  end
end
