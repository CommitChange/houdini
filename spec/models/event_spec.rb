# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

RSpec.describe Event, type: :model do
  it { is_expected.to belong_to(:nonprofit) }
  it { is_expected.to have_many(:ticketholders).through(:tickets).source(:supporter) }
  it { is_expected.to define_enum_for(:in_person_or_virtual).with_values(%w[in_person virtual].index_by(&:itself)).backed_by_column_of_type(:string).validating }
  it { is_expected.to delegate_method(:timezone).to(:nonprofit).with_prefix.allow_nil }

  describe "#virtual_or_valid_address" do
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_presence_of(:state_code) }

    context "when #virtual is true" do
      subject { Event.new(in_person_or_virtual: "virtual") }
      it { is_expected.to_not validate_presence_of(:address) }
      it { is_expected.to_not validate_presence_of(:city) }
      it { is_expected.to_not validate_presence_of(:state_code) }
    end
  end

  describe "#timezone_with_fallback" do
    let(:nonprofit) { create(:nonprofit_base, timezone: 'America/Los_Angeles') }
    let(:event) { create(:event_base, nonprofit:, timezone: 'America/Central') }
    let(:event_without_timezone) { create(:event_base, nonprofit:) }

    it "returns the event timezone with priority" do
      expect(event.timezone_with_fallback).to eq('America/Central')
    end

    it "returns the nonprofit timezone if event timezone is not set" do
      expect(event_without_timezone.timezone_with_fallback).to eq(nonprofit.timezone)
    end
  end
end
