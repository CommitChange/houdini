# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class PeriodicReportAdapter::StartedRecurringDonationsToCsvReport < PeriodicReportAdapter
  def initialize(options)
    @nonprofit_id = options[:nonprofit_id]
    @period = options[:period]
    @users = options[:users]
    @nonprofit_s3_key = options[:nonprofit_s3_key]
    @filename = options[:filename]
  end

  def run
    StartedRecurringDonationsToCsvJob.perform_later params
  end

  private
  
  def nonprofit
    Nonprofit.find(@nonprofit_id)
  end

  def params
    { nonprofit: nonprofit, nonprofit_s3_key: @nonprofit_s3_key, user: @users.first, filename: @filename }
  end
end
