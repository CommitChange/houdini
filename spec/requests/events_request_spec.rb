# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

describe EventsController, type: :request do
  let(:nonprofit) { create(:nonprofit_base) }
  let(:user) { create(:user_base, roles: [build(:role_base, name: "nonprofit_associate", host: nonprofit)]) }
  let(:profile) { create(:profile, user:) }
  let!(:events) do
    OpenStruct.new(
      deleted: create(:event_base, nonprofit:, deleted: true),
      last: create(:event_base, nonprofit:, name: "Last event"),
      first: create(:event_base, nonprofit:, name: "First event")
    )
  end

  before do
    sign_in user
  end

  describe "POST /nonprofit/:nonprofit_id/events" do
    before do
      expect_any_instance_of(Event).to receive(:geocode).and_return([1, 1]) # otherwise the geocode call fails
    end

    context "with valid params" do
      let(:params) { { event: attributes_for(:event_base, nonprofit_id: nonprofit.id, profile_id: profile.id) } }

      it "creates a new event" do
        expect { post(nonprofit_events_path(nonprofit), params:) }.to change(Event, :count).by(1)
      end

      it "returns a success status" do
        post(nonprofit_events_path(nonprofit), params:)
        expect(response).to have_http_status(:success)
      end

      it "sets the flash" do
        post(nonprofit_events_path(nonprofit), params:)
        expect(flash[:notice]).to eq("Your draft event has been created! Well done.")
      end

      it "returns the response" do
        post(nonprofit_events_path(nonprofit), params:)
        json = JSON.parse(response.body)
        expect(json.dig('event', 'name')).to eq(params[:event][:name])
        expect(json['url']).to eq("/events/#{params[:event][:slug]}")
      end
    end

    context "with invalid params" do
      let(:params) { { event: attributes_for(:event_base).merge(name: nil) } }

      it "does not create a new event" do
        expect { post(nonprofit_events_path(nonprofit), params:) }.not_to change(Event, :count)
      end

      it "returns a success status" do
        post(nonprofit_events_path(nonprofit), params:)
        expect(response).to have_http_status(:success)
      end

      it "returns the response" do
        post(nonprofit_events_path(nonprofit), params:)
        json = JSON.parse(response.body)
        expect(json.dig('event', 'id')).to be_nil
        expect(json.dig('event', 'name')).to be_nil
      end
    end
  end




  describe "GET name_and_id" do
    it "contains the events in order from first, to last with no deleted events" do
      get name_and_id_nonprofit_events_path(nonprofit)

      result = JSON.parse(response.body)

      expect(result).to include_json([
        {name: events.first.name, id: events.first.id},
        {name: events.last.name, id: events.last.id}
      ])
    end
  end
end
