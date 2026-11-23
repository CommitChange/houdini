# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe MigrateAddSupporterAndNonprofitToRefundTask do
    let!(:refund_with_supporter_id) { create(:refund, supporter_id: 1, nonprofit_id: nil, charge: create(:charge_base)) }
    let!(:refund_with_nonprofit_id) { create(:refund, supporter_id: nil, nonprofit_id: 1, charge: create(:charge_base)) }
    let!(:refund_with_both) { create(:refund, supporter_id: 1, nonprofit_id: 1, charge: create(:charge_base)) }
    let!(:refund_with_neither) { create(:refund, supporter_id: nil, nonprofit_id: nil, charge: create(:charge_base)) }

    let(:refund_with_no_charge) { create(:refund, supporter_id: nil, nonprofit_id: nil) }
    describe "#process" do
      subject(:process) { described_class.process(element) }
      context "Refund has a charge set " do
        let(:element) { refund_with_neither }
        it "sets the nonprofit_id and supporter_id" do
          process
          expect(element).to have_attributes(
            nonprofit_id: refund_with_neither.charge.nonprofit_id,
            supporter_id: refund_with_neither.charge.supporter_id
          )
        end
      end

      context "Refund has no charge set " do
        let(:element) { refund_with_no_charge }
        it "doesn't set nonprofit_id and supporter_id" do
          process
          expect(element).to have_attributes(
            nonprofit_id: nil,
            supporter_id: nil
          )
        end
      end
    end

    describe "#collection" do
      let(:expected_refunds) { [refund_with_nonprofit_id, refund_with_supporter_id, refund_with_neither] }

      it "returns refunds with supporter_id or nonprofit_id set but nothing else" do
        expect(described_class.collection).to match_array(expected_refunds)
      end
    end
  end
end
