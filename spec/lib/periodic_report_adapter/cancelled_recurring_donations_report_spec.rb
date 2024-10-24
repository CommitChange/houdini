# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

describe PeriodicReportAdapter::CancelledRecurringDonationsReport do
  let(:nonprofit) { create(:nonprofit_base) }
  let(:user) { create(:user) }
  let(:users_list) { User.where(user_id: user) }
  let(:options) do
    {
      :nonprofit_id => nonprofit.id,
      :period => :last_month,
      :users => users_list
    }
  end

  let(:params) do
    {
      :active => false,
      :cancelled_at_gt_or_eq => Time.new(2021, 9, 1),
      :cancelled_at_lt => Time.new(2021, 10, 1)
    }
  end

  let(:export_recurring_donations) { double }

  subject { described_class.new(options).run }

  around(:each) do |e|
    Timecop.freeze(2021, 10, 21) do
      e.run
    end
  end

  before do
    allow(ExportRecurringDonations)
      .to receive(:initiate_export)
      .with(nonprofit.id, params, users_list, :cancelled_recurring_donations_automatic_report)
      .and_return(export_recurring_donations)
  end

  it 'calls ExportRecurringDonations::initiate_export with the correct arguments' do
    subject
    expect(ExportRecurringDonations)
      .to have_received(:initiate_export)
      .with(nonprofit.id, params, users_list, :cancelled_recurring_donations_automatic_report)
  end
end
