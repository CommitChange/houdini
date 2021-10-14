# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later

module ExportFailedRecurringDonations

  def self.initiate_export(npo_id, user_id)
    params = { :failed => true, :started_at => (Time.current - 1.month).beginning_of_month, :end_date => Time.current.beginning_of_day, :include_last_failed_charge => true }
    completed_notification_method = method(:export_failed_recurring_donations_monthly_completed_notification)
    failed_notification_method = method(:export_failed_recurring_donations_monthly_failed_notification)

    ExportRecurringDonations::initiate_export(npo_id, params, user_id, completed_notification_method, failed_notification_method)
  end

  def self.export_failed_recurring_donations_monthly_completed_notification(export)
    ExportMailer.delay.export_failed_recurring_donations_monthly_completed_notification(export)
  end

  def self.export_failed_recurring_donations_monthly_failed_notification(export)
    ExportMailer.delay.export_failed_recurring_donations_monthly_failed_notification(export)
  end
end
