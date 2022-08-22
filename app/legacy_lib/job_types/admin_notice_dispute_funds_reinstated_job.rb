# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module JobTypes
  class AdminNoticeDisputeFundsReinstatedJob < EmailJob
    attr_reader :dispute

    def initialize(dispute)
      @dispute = dispute
    end

    def perform
      DisputeMailer.funds_reinstated(dispute).deliver
    end
  end
end