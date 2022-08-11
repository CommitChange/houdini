# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module JobTypes
  class AdminNoticeDisputeWonJob < EmailJob
    attr_reader :dispute

    def initialize(dispute)
      @dispute = dispute
    end

    def perform
      DisputeMailer.won(dispute).deliver
    end
  end
end