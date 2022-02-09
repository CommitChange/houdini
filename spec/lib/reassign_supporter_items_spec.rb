# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

describe ReassignSupporterItems do
    describe '#perform' do
        let(:nonprofit) { create(:fv_poverty) }
        let(:supporter) { nonprofit.supporters.create(name: 'Cacau', email: 'cacau@cacau.com') }
        let(:other_supporter) { nonprofit.supporters.create(name: 'Eric') }
        let(:row) { { 'Account Number' => '12345', 'Account Name' => 'Cacau' } }
        let!(:etap_import) { create(:e_tap_import, nonprofit: nonprofit) }

        before do
            etap_import.e_tap_import_journal_entries.create(row: row)
            etap_import.e_tap_import_journal_entries.first.journal_entries_to_items.create(item: supporter.supporter_notes.create(content: 'Some note'))
        end

        context 'when all items are assigned to the correct supporter' do
            it 'returns an empty array' do
                InsertCustomFieldJoins.find_or_create(nonprofit.id, [supporter.id], [['E-Tapestry Id #', '12345' ]])
                create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, supporter_id: supporter.id, row: row)
                expect(described_class.perform(etap_import)).to eq([])
            end
        end

        context 'when some items are assigned to the wrong supporter' do
            it 'reassigns the item to the correct supporter' do
                InsertCustomFieldJoins.find_or_create(nonprofit.id, [supporter.id], [['E-Tapestry Id #', '12345' ]])
                create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: row)
                item = etap_import.e_tap_import_journal_entries.first.journal_entries_to_items.create(item: other_supporter.supporter_notes.create(content: 'Some note')).item

                expect { described_class.perform(etap_import) }.to change { item.reload.supporter }.from(other_supporter).to(supporter)
            end

            it 'reassigns the activity to the correct supporter' do
                InsertCustomFieldJoins.find_or_create(nonprofit.id, [supporter.id], [['E-Tapestry Id #', '12345' ]])
                create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: row)
                item = etap_import.e_tap_import_journal_entries.first.journal_entries_to_items.create(item: other_supporter.supporter_notes.create(content: 'Some note')).item
                activity = Activity.find_by(attachment_id: item.id, supporter: other_supporter)

                expect { described_class.perform(etap_import) }.to change { activity.reload.supporter }.from(other_supporter).to(supporter)
            end

            it 'returns an empty array' do
                InsertCustomFieldJoins.find_or_create(nonprofit.id, [supporter.id], [['E-Tapestry Id #', '12345' ]])
                create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: row)
                etap_import.e_tap_import_journal_entries.first.journal_entries_to_items.create(item: other_supporter.supporter_notes.create(content: 'Some note'))

                expect(described_class.perform(etap_import)).to eq([])
            end

            context 'when the contact does not have a matching supporter by account id' do
                before do
                    InsertCustomFieldJoins.find_or_create(nonprofit.id, [supporter.id], [['E-Tapestry Id #', '54321' ]])
                end

                it 'tries to find by the account name or email' do
                    e_tap_import_contact = create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: row)
                    e_tap_import_contact = create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: { 'Email' => 'cacau@cacau.com', 'Account Number' => '54321'})
                    etap_import.e_tap_import_journal_entries.first.journal_entries_to_items.create(item: other_supporter.supporter_notes.create(content: 'Some note'))
                    allow(ETapImportContact)
                        .to receive(:find_by_account_name)
                        .with('Cacau', 'cacau@cacau.com', '12345')
                        .twice

                    described_class.perform(etap_import)
                    expect(ETapImportContact)
                        .to have_received(:find_by_account_name)
                        .with('Cacau', 'cacau@cacau.com', '12345')
                        .twice
                end

                context 'when there is other corresponding contact' do
                    it 'reassigns the item to the correct supporter' do
                        e_tap_import_contact = create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: { 'Account Name' => 'Cacau', 'Account Number' => '54321'})
                        e_tap_import_contact = create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: row)
                        item = etap_import.e_tap_import_journal_entries.first.journal_entries_to_items.create(item: other_supporter.supporter_notes.create(content: 'Some note')).item

                        expect { described_class.perform(etap_import) }.to change { item.reload.supporter }.from(other_supporter).to(supporter)
                    end

                    it 'reassigns the activity to the correct supporter' do
                        e_tap_import_contact = create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: { 'Email' => 'cacau@cacau.com', 'Account Number' => '54321'})
                        create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: row)
                        item = etap_import.e_tap_import_journal_entries.first.journal_entries_to_items.create(item: other_supporter.supporter_notes.create(content: 'Some note')).item
                        activity = Activity.find_by(attachment_id: item.id, supporter: other_supporter)

                        expect { described_class.perform(etap_import) }.to change { activity.reload.supporter }.from(other_supporter).to(supporter)
                    end

                    it 'returns an empty array' do
                        e_tap_import_contact = create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: { 'Account Name' => 'Cacau', 'Account Number' => '54321'})
                        e_tap_import_contact = create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: row)
                        item = etap_import.e_tap_import_journal_entries.first.journal_entries_to_items.create(item: other_supporter.supporter_notes.create(content: 'Some note')).item

                        expect(described_class.perform(etap_import)).to eq([])
                    end
                end

                context 'when there are no matches' do
                    it 'returns an array with the bad data' do
                        e_tap_import_contact = create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: { 'Account Name' => 'Penelope', 'Account Number' => '54321'})
                        e_tap_import_contact = create(:e_tap_import_contact, nonprofit: nonprofit, e_tap_import: etap_import, row: row)
                        item = etap_import.e_tap_import_journal_entries.first.journal_entries_to_items.create(item: other_supporter.supporter_notes.create(content: 'Some note')).item

                        expect(described_class.perform(etap_import).first).to include(:etije, :etije_id, :supp_through_contact, :journal_entries_to_items_with_wrong_supporter)
                    end
                end
            end
        end
    end
end
