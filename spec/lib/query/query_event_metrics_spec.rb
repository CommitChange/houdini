# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

describe QueryEventMetrics do
  let(:nonprofit) { create(:nonprofit_base) }
  let(:supporter) { create(:supporter_base, nonprofit:) }
  let(:supporter2) { create(:supporter_base, nonprofit:) }

  let!(:event_active1) do
    create(:event_base, nonprofit:, published: true, organizer_email: "organizer1@example.com",
      start_datetime: 10.days.ago.at_beginning_of_day, end_datetime: 10.days.since.at_beginning_of_day)
  end

  let!(:event_active2) do
    create(:event_base, nonprofit:, published: true, organizer_email: "organizer2@example.com",
      start_datetime: 10.days.ago.at_beginning_of_day, end_datetime: 20.days.since.at_beginning_of_day)
  end

  let!(:ticket_level) { create(:ticket_level, event: event_active2, name: "General admission") }

  # Two tickets, two payments (21.37 + 10.85 = $32.22)
  let!(:ticket_payment1) { create(:payment, supporter:, nonprofit:, gross_amount: 2137, fee_total: -159, net_amount: 1978) }
  let!(:ticket1) { create(:ticket, event: event_active2, supporter:, payment: ticket_payment1, ticket_level:, checked_in: true, quantity: 4) }
  let!(:ticket_payment2) { create(:payment, supporter:, nonprofit:, gross_amount: 1085, fee_total: -85, net_amount: 1000) }
  let!(:ticket2) { create(:ticket, event: event_active2, supporter: supporter2, payment: ticket_payment2, ticket_level:, checked_in: nil, quantity: 3) }

  # Two donations (26.64 + 52.95 = $79.59)
  let!(:donation_payment1) { create(:payment, supporter:, nonprofit:, gross_amount: 2664, fee_total: -164, net_amount: 2500) }
  let!(:donation1) { create(:donation_base, supporter:, nonprofit:, event: event_active2, amount: 2664, payment: donation_payment1) }
  let!(:donation_payment2) { create(:payment, supporter:, nonprofit:, gross_amount: 5295, fee_total: -295, net_amount: 5000) }
  let!(:donation2) { create(:donation_base, supporter:, nonprofit:, event: event_active2, amount: 5295, payment: donation_payment2) }

  let!(:event_past) { create(:event_base, nonprofit:, published: true, start_datetime: 21.days.ago, end_datetime: 20.days.ago.at_beginning_of_day) }
  let!(:event_deleted) { create(:event_base, nonprofit:, deleted: true) }
  let!(:event_unpublished) { create(:event_base, nonprofit:) }

  let!(:other_nonprofit) { create(:nonprofit_base) }
  let!(:other_event_active1) { create(:event_base, nonprofit: other_nonprofit, published: true, end_datetime: 10.days.since) }
  let!(:other_event_active2) { create(:event_base, nonprofit: other_nonprofit, published: true, end_datetime: 20.days.since) }

  describe ".for_listings" do
    describe "for nonprofit" do
      describe "active" do
        subject(:results) { QueryEventMetrics.for_listings("nonprofit", nonprofit.id, {"active" => true}) }

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
          expect(results.first["total_paid"]).to eq(3_222 + 7_959)

          expect(results.last["id"]).to eq event_active1.id
        end
      end

      describe "past" do
        subject(:results) { QueryEventMetrics.for_listings("nonprofit", nonprofit.id, {"past" => true}) }

        it "query result has correct element" do
          expect(results.count).to eq 1
          expect(results.first["id"]).to eq event_past.id
        end
      end

      describe "unpublished" do
        subject(:results) { QueryEventMetrics.for_listings("nonprofit", nonprofit.id, {"unpublished" => true}) }

        it "query result has correct element" do
          expect(results.count).to eq 1
          expect(results.first["id"]).to eq event_unpublished.id
        end
      end

      describe "deleted" do
        subject(:results) { QueryEventMetrics.for_listings("nonprofit", nonprofit.id, {"deleted" => true}) }

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
