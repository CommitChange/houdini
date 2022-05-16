# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class ActiveRecurringDonationsToJsonJob < ExportJob
  queue_as :default

  def perform(nonprofit, user, export)
    url = ExportRecurringDonations.run_export_for_active_recurring_donations_to_json(export)
    export.update(url: url)
  end

end
