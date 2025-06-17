# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

describe QueryEventMetrics do
  let(:nonprofit) { create(:nonprofit, slug: SecureRandom.uuid) }
  let(:user) { create(:user) }
  let(:profile) { create(:profile, user:) }
  let(:supporter) { create(:supporter, nonprofit:, profile:, import: create(:import, user:, nonprofit:)) }
  let(:supporter2) { create(:supporter, nonprofit:, import: create(:import, nonprofit:)) }

  let!(:event_active1) do
    event = create(:event, nonprofit:,
                   name: Faker::FunnyName.four_word_name,
                   organizer_email: Faker::Internet.email,
                   end_datetime: 10.days.since.at_beginning_of_day, start_datetime: 10.days.ago.at_beginning_of_day, published: true, slug: SecureRandom.uuid,
                   address: Faker::Address.street_address, city: Faker::Address.city, state_code: Faker::Address.state_abbr, zip_code: Faker::Address.zip)
  end

  let!(:event_active2) do
    create(:event, nonprofit:,
                   name: Faker::FunnyName.four_word_name,
                   organizer_email: Faker::Internet.email,
                   end_datetime: 20.days.since.at_beginning_of_day, start_datetime: 10.days.ago.at_beginning_of_day, published: true, slug: SecureRandom.uuid,
                   address: Faker::Address.street_address, city: Faker::Address.city, state_code: Faker::Address.state_abbr, zip_code: Faker::Address.zip)
  end

  let!(:tl1) { create(:ticket_level, event: event_active2) }
  let!(:payment1) { create(:payment, supporter:, nonprofit:, gross_amount: 2137, fee_total: -159, net_amount: 1978) }
  let!(:ticket1) { create(:ticket, event: event_active2, supporter:, profile:, payment: payment1, ticket_level: tl1, checked_in: true, quantity: 4) }

  let!(:payment2) { create(:payment, supporter:, nonprofit:, gross_amount: 1085, fee_total: -85, net_amount: 1000) }
  let!(:ticket2) { create(:ticket, event: event_active2, supporter: supporter2, payment: payment2, ticket_level: tl1, checked_in: nil, quantity: 3) }
  # Two tickets, two payments (21.37 + 10.85 = $32.22)

  let!(:donation_payment1) { create(:payment, supporter:, nonprofit:, gross_amount: 2664, fee_total: -164, net_amount: 2500) }
  let!(:donation1) { create(:donation, supporter:, nonprofit:, event: event_active2, card: create(:card), amount: 2664, payment: donation_payment1) }

  let!(:donation_payment2) { create(:payment, supporter:, nonprofit:, gross_amount: 5295, fee_total: -295, net_amount: 5000) }
  let!(:donation2) { create(:donation, supporter:, nonprofit:, event: event_active2, card: create(:card), amount: 5295, payment: donation_payment2) }
  # Two donations 2664 + 5295 = $79.59

  let!(:event_past) { create(:event, nonprofit:, end_datetime: 20.days.ago.at_beginning_of_day, published: true, slug: SecureRandom.uuid) }
  let!(:event_deleted) { create(:event, nonprofit:, deleted: true, slug: SecureRandom.uuid) }
  let!(:event_unpublished) { create(:event, nonprofit:, slug: SecureRandom.uuid) }

  let!(:nonprofit2) { create(:nonprofit, slug: SecureRandom.uuid) }
  let!(:other_event_active2) { create(:event, nonprofit: nonprofit2, end_datetime: 10.days.since, published: true, slug: SecureRandom.uuid) }
  let!(:other_event_active3) { create(:event, nonprofit: nonprofit2, end_datetime: 20.days.since, published: true, slug: SecureRandom.uuid) }

  describe ".for_listings" do
    describe "for nonprofit" do
      describe "active" do
        subject(:results) { QueryEventMetrics.for_listings("nonprofit", nonprofit.id, {"active" => true})}

        it "query result has correct attributes" do
          expect(results.count).to eq 2

          # first element is event_active2 because of order desc
          expect(results.first["id"]).to eq event_active2.id
          expect(results.first["name"]).to eq event_active2.name
          expect(results.first["venue_name"]).to eq event_active2.venue_name
          expect(results.first["address"]).to eq event_active2.address
          expect(results.first["city"]).to eq event_active2.city
          expect(results.first["state_code"]).to eq event_active2.state_code
          expect(results.first["zip_code"]).to eq event_active2.zip_code
          expect(results.first["start_datetime"]).to eq 10.days.ago.at_beginning_of_day
          expect(results.first["end_datetime"]).to eq 20.days.since.at_beginning_of_day
          expect(results.first["organizer_email"]).to eq event_active2.organizer_email
          expect(results.first["checked_in_count"]).to eq 1
          expect(results.first["total_attendees"]).to eq 7
          expect(results.first["tickets_total_paid"]).to eq 3_222
          expect(results.first["donations_total_paid"]).to eq 7_959
          expect(results.first["total_paid"]).to eq (3_222 + 7_959)

          expect(results.last["id"]).to eq event_active1.id
        end
      end

      describe "active" do
        subject(:results) { QueryEventMetrics.for_listings("nonprofit", nonprofit.id, {"past" => true})}
        it "query result has correct element" do
          expect(results.count).to eq 1
          expect(results.first["id"]).to eq event_past.id
        end
      end

      describe "unpublished" do
        subject(:results) { QueryEventMetrics.for_listings("nonprofit", nonprofit.id, {"unpublished" => true})}
        it "query result has correct element" do
          expect(results.count).to eq 1
          expect(results.first["id"]).to eq event_unpublished.id
        end
      end

      describe "deleted" do
        subject(:results) { QueryEventMetrics.for_listings("nonprofit", nonprofit.id, {"deleted" => true})}
        it "query result has correct element" do
          expect(results.count).to eq 1
          expect(results.first["id"]).to eq event_deleted.id
        end
      end
    end

    describe "for profile" do
      skip "TODO"
    end
  end

  describe ".with_event_ids" do
    skip "TODO"
  end
end
