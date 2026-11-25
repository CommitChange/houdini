# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"
require "controllers/support/shared_user_context"

describe RecurringDonationsController, type: :controller do
  describe "authorization" do
    include_context :shared_user_context
    describe "open to all (note: edit token is checked inside methods)" do
      describe "edit" do
        include_context :open_to_all, :get, :edit, nonprofit_id: :__our_np, id: "1", without_json_view: true
      end

      describe "destroy" do
        include_context :open_to_all, :delete, :destroy, nonprofit_id: :__our_np, id: "1"
      end

      describe "update" do
        include_context :open_to_all, :put, :update, nonprofit_id: :__our_np, id: "1"
      end

      describe "update_amount" do
        include_context :open_to_all, :put, :update_amount, nonprofit_id: :__our_np, id: "1"
      end
    end
  end

  describe "Slipflow's recurring donation" do
    let!(:automated_user) { create(:automated_user) }
    let(:rd) { create_slipflow_recurring_donation(paydate: 5) }

    it "refuses a new paydate" do
      put :update, params: {id: rd.id, edit_token: rd.edit_token, paydate: 10}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq(RecurringDonation::SLIPFLOW_EDIT_REFUSAL)
      expect(rd.reload.paydate).to eq(5)
    end

    it "refuses a new card" do
      card = force_create(:card, holder: rd.supporter)
      token = force_create(:source_token, tokenizable: card, expiration: 1.day.from_now, max_uses: 1, token: SecureRandom.uuid).token

      put :update, params: {id: rd.id, edit_token: rd.edit_token, token: token}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(rd.donation.reload.card_id).to be_nil
    end

    it "refuses a new amount" do
      card = force_create(:card, holder: rd.supporter)
      token = force_create(:source_token, tokenizable: card, expiration: 1.day.from_now, max_uses: 1, token: SecureRandom.uuid).token

      put :update_amount, params: {id: rd.id, edit_token: rd.edit_token, token: token, amount: 2000}

      expect(response).to have_http_status(:unprocessable_entity)
      expect([rd.reload.amount, rd.n_failures]).to eq([1000, 0])
    end

    it "cancels" do
      delete :destroy, params: {id: rd.id, edit_token: rd.edit_token}

      expect(response).to have_http_status(:ok)
      expect(rd.reload.active).to eq(false)
    end
  end

  describe "a CC recurring donation" do
    let!(:automated_user) { create(:automated_user) }
    let(:rd) { force_create(:recurring_donation_base, donation: force_create(:donation, amount: 1000), nonprofit: force_create(:nonprofit), paydate: 5) }

    it "takes a new paydate" do
      put :update, params: {id: rd.id, edit_token: rd.edit_token, paydate: 10}

      expect(response).to have_http_status(:ok)
      expect(rd.reload.paydate).to eq(10)
    end
  end
end
