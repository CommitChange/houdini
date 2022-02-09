# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
module ReassignSupporterItems
    def self.perform(etap_import)
        badly_assigned_items = find_badly_assigned_items(etap_import)
        ActiveRecord::Base.transaction do
            badly_assigned_items.each do |items|
                reassign_journal_entries(items[:supp_through_contact], items[:journal_entries_to_items_with_wrong_supporter], etap_import)
            end
        end
        remaining_badly_assigned_items = find_badly_assigned_items(etap_import)
    end

    def self.find_badly_assigned_items(etap_import)
        etap_import.e_tap_import_journal_entries.find_each.map do |etije|
            supp_through_contact = etije.supporter_through_e_tap_import_contact
            if supp_through_contact.blank?
                supp_through_contact = ETapImportContact.find_by_account_name(etije.journal_entries_to_items.first.item.supporter.name, etije.journal_entries_to_items.first.item.supporter.email, etije.account_id)&.supporter
            end
            if etije.journal_entries_to_items.select{|i| i.item.supporter != supp_through_contact}.any?
                {
                    etije: etije,
                    etije_id: etije.id,
                    supp_through_contact: supp_through_contact,
                    journal_entries_to_items_with_wrong_supporter: etije.journal_entries_to_items.select{|i| i.item.supporter != supp_through_contact}
                }
            else
                nil
            end
        end.compact
    end

    def self.reassign_journal_entries(correct_supporter, journal_entries_to_items_with_wrong_supporter, etap_import)
        return if correct_supporter.blank?

        journal_entries_to_items_with_wrong_supporter.each do |journal_entry|
            reassign_item(correct_supporter, journal_entry.item, etap_import)
        end
    end

    def self.reassign_item(correct_supporter, item, etap_import)
        activity = Activity.find_by(attachment_id: item.id, supporter: item.supporter)
        etap_import.reassignments.create(item: item, source_supporter: item.supporter, target_supporter: correct_supporter)
        item.supporter = correct_supporter
        item.save!
        if activity.present?
            etap_import.reassignments.create(item: activity, source_supporter: activity.supporter, target_supporter: correct_supporter)
            activity.supporter = correct_supporter
            activity.save!
        end
    end

    def self.revert_reassignments_from_supporter(supporter)
        reassignments = Reassignment.where(target_supporter: supporter)
        reassignments.each do |reassignment|
            reassign_item(reassignment.source_supporter, reassignment.item, reassignment.e_tap_import)
        end
        reassignments.destroy_all
    end

    def self.revert_all_reassignments(etap_import)
        reassignments = Reassignment.where(e_tap_import: etap_import)
        reassignments.each do |reassignment|
            reassign_item(reassignment.source_supporter, reassignment.item, reassignment.e_tap_import)
        end
        reassignments.destroy_all
    end
end
