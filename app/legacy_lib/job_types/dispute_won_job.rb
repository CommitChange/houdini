# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module JobTypes
  class DisputeWonJob < GenericJob
    attr_reader :dispute

    def initialize(dispute)
      @dispute = dispute
    end

    def perform
      JobQueue.queue(JobTypes::AdminNoticeDisputeWonJob, dispute)
    end
  end
end