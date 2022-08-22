# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module JobTypes
  class ExportSupporterNotesFailedJob < EmailJob
    attr_reader :export

    def initialize(export)
      @export = export
    end

    def perform
      ExportMailer.export_supporter_notes_failed_notification(@export).deliver
    end
  end
end