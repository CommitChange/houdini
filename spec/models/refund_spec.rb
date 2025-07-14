# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

RSpec.describe Refund, type: :model do
  it { is_expected.to belong_to(:charge).required(true) }
  it { is_expected.to belong_to(:payment).required(true) }
  it { is_expected.to have_one(:subtransaction_payment).through(:payment) }
  it { is_expected.to have_one(:misc_refund_info) }

  it { is_expected.to have_one(:nonprofit).through(:charge) }
  it { is_expected.to have_one(:supporter).through(:charge) }
  it { is_expected.to have_many(:manual_balance_adjustments) }

  it { is_expected.to validate_presence_of(:amount) }
  it { is_expected.to validate_numericality_of(:amount).only_integer.is_greater_than(0) }

  describe "#from_donation?" do
    it "is true when refund is associated with a donation" do
      expect(build(:refund, :from_donation).from_donation?).to eq true
    end

    it "is true when refund is not associated with a donation" do
      expect(build(:refund, :not_from_donation).from_donation?).to eq false
    end
  end
end
