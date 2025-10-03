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
