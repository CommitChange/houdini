# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class PeriodicReportAdapter::ActiveRecurringDonationsToCsvReport < PeriodicReportAdapter
  def initialize(options)
    @nonprofit_id = options[:nonprofit_id]
    @user_ids = options[:users].pluck(:id)
  end

  def run
    ActiveRecurringDonationsToCsvJob.perform_later params
  end

  private

  def params
    { nonprofit: nonprofit }
  end

  def nonprofit
    Nonprofit.find(@nonprofit_id)
  end
end