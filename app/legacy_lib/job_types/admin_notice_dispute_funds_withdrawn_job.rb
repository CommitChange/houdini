# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module JobTypes
  class AdminNoticeDisputeFundsWithdrawnJob < EmailJob
    attr_reader :dispute

    def initialize(dispute)
      @dispute = dispute
    end

    def perform
      DisputeMailer.funds_withdrawn(dispute).deliver
    end
  end
end