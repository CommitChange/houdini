# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class PeriodicReportAdapter::StartedRecurringDonationsToJsonReport < PeriodicReportAdapter
  def initialize(options)
    @nonprofit_id = options[:nonprofit_id]
    @period = options[:period]
    @user_ids = options[:users].pluck(:id)
  end

  def run
    StartedRecurringDonationsToJsonJob.perform_later params
  end

  private

  def params
    { nonprofit: nonprofit }
  end
end
