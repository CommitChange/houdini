# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

RSpec.describe RecurringDonation, type: :model do
  before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end
  describe "commonly used values" do
    let!(:cancelled) { force_create(:recurring_donation, active: false, n_failures: 0) }

    let!(:failed) { force_create(:recurring_donation, active: true, n_failures: 3) }

    let!(:normal) { force_create(:recurring_donation, active: true, n_failures: 2) }

    let!(:ended) { force_create(:recurring_donation, active: true, n_failures: 2, end_date: 1.day.ago) }

    let!(:ends_in_future) { force_create(:recurring_donation, active: true, n_failures: 0, end_date: 1.day.from_now) }
    describe ".will_attempt_again?" do
      it "wont if cancelled" do
        expect(cancelled).to_not be_will_attempt_again
      end

      it "wont if failed" do
        expect(failed).to_not be_will_attempt_again
      end

      it "will if not failed or cancelled" do
        expect(normal).to be_will_attempt_again
      end

      it "wont if ended" do
        expect(ended).to_not be_will_attempt_again
      end

      it "will if ends in future" do
        expect(ends_in_future).to be_will_attempt_again
      end
    end

    describe ".may_attempt_again scope" do
      subject { RecurringDonation.may_attempt_again }

      it { is_expected.to include normal }

      it { is_expected.to_not include cancelled }

      it { is_expected.to_not include failed }

      it { is_expected.to_not include ended }

      it { is_expected.to include ends_in_future }
    end
  end

  describe "#cancel!" do
    # it 'requires an email' do
    #   expect{ build_stubbed(:recurring_donation_base).cancel!}.to raise_error ArgumentError
    # end

    def uncancelled_recurring_donation
      supporter = create(:supporter_base, :with_1_active_mailing_list)
      nonprofit = supporter.nonprofit
      donation = create(:donation_base, nonprofit: nonprofit, supporter_id: supporter.id, amount: 999)
      create(:recurring_donation_base, nonprofit: nonprofit, supporter_id: supporter.id, donation: donation)
    end

    def cancelled_recurring_donation
      supporter = create(:supporter_base, :with_1_active_mailing_list)
      nonprofit = supporter.nonprofit
      donation = create(:donation_base, nonprofit: nonprofit, supporter_id: supporter.id, amount: 999)
      create(:recurring_donation_base, :nonprofit => nonprofit, :supporter_id => supporter.id, :donation => donation, :active => false, "cancelled_at" => Time.new(2020, 5, 4),
        "cancelled_by" => "penelope@rebecca.schultz")
    end

    it "cancels an rd properly" do
      expect(RecurringDonationCreatedJob).to_not have_been_enqueued
      recurring_donation = uncancelled_recurring_donation
      Timecop.freeze Time.new(2020, 5, 4) do
        recurring_donation.cancel!("penelope@rebecca.schultz")
        expect(recurring_donation).to have_attributes(
          "active" => false,
          "cancelled_at" => Time.new(2020, 5, 4),
          "cancelled_by" => "penelope@rebecca.schultz"
        )

        expect(recurring_donation).to be_cancelled

        expect(recurring_donation).to be_persisted
        expect(RecurringDonationCancelledJob).to have_been_enqueued
      end
    end

    it "doesnt recancel an already cancelled recurring donation" do
      expect(RecurringDonationCreatedJob).to_not have_been_enqueued
      expect(RecurringDonationCancelledJob).to_not have_been_enqueued
      recurring_donation = cancelled_recurring_donation
      Timecop.freeze Time.new(2020, 5, 4) do
        expect(RecurringDonationCancelledJob).to_not have_been_enqueued
        recurring_donation.cancel!("eric@david.schultz")
        expect(recurring_donation).to have_attributes(
          "active" => false,
          "cancelled_at" => Time.new(2020, 5, 4),
          "cancelled_by" => "penelope@rebecca.schultz"
        )

        expect(recurring_donation).to be_cancelled

        expect(recurring_donation).to be_persisted

        expect(RecurringDonationCancelledJob).to_not have_been_enqueued
      end
    end
  end

  describe "Slipflow's" do
    let(:slipflow_rd) { create_slipflow_recurring_donation }
    let(:cc_rd) { force_create(:recurring_donation, active: true, n_failures: 0) }

    it "is Slipflow's when its donation's charge started a stripe_recurrence" do
      expect(slipflow_rd).to be_slipflow
      expect(RecurringDonation.slipflow).to contain_exactly(slipflow_rd)
      expect(RecurringDonation.not_slipflow).not_to include(slipflow_rd)
    end

    it "isn't Slipflow's, though Slipflow charged it, when its donation's Slipflow charge started no stripe_recurrence" do
      donation = force_create(:donation, amount: 1000)
      add_slipflow_charge(donation, start_recurrence: false)
      rd = force_create(:recurring_donation, donation: donation, active: true, n_failures: 0)

      expect(rd).not_to be_slipflow
      expect(rd).to be_slipflow_charged
      expect(slipflow_rd).to be_slipflow_charged
      expect(cc_rd).not_to be_slipflow_charged
    end

    it "isn't Slipflow's without a Slipflow charge" do
      expect(cc_rd).not_to be_slipflow
      expect(RecurringDonation.not_slipflow).to include(cc_rd)
    end

    it "refuses edits" do
      expect { slipflow_rd.refuse_edit_if_slipflow! }.to raise_error(ParamValidation::ValidationError, RecurringDonation::SLIPFLOW_EDIT_REFUSAL)
      expect { cc_rd.refuse_edit_if_slipflow! }.not_to raise_error
    end

    it "can't be put on hold" do
      expect(slipflow_rd.build_recurring_donation_hold(end_date: 1.month.from_now)).not_to be_valid
      expect(cc_rd.build_recurring_donation_hold(end_date: 1.month.from_now)).to be_valid
    end
  end
end
