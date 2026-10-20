# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

describe NonprofitMetrics do
  describe ".payment_history" do
    let(:nonprofit) { force_create(:nonprofit) }
    let(:params) { {id: nonprofit.id, startDate: "2026-01-01", endDate: "2026-03-31", timeSpan: "month"} }

    it "returns one row per time span" do
      expect(NonprofitMetrics.payment_history(params).map { |r| r["time_span"] })
        .to eq ["2026-01-01", "2026-02-01", "2026-03-01"]
    end

    ["hour", "", nil, "month'"].each do |time_span|
      it "rejects timeSpan #{time_span.inspect} before running any query" do
        expect(Qx).not_to receive(:select)
        expect { NonprofitMetrics.payment_history(params.merge(timeSpan: time_span)) }
          .to raise_error(ArgumentError, "Invalid timespan")
      end
    end
  end
end
