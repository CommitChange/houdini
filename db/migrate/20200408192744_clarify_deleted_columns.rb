class ClarifyDeletedColumns < ActiveRecord::Migration
  def up
    TagMaster.where(deleted: nil).update_all(deleted: false)
    change_column(:tag_masters, :deleted, :boolean, default: false)

    TicketLevel.where(deleted: nil).update_all(deleted: false)
    change_column(:ticket_levels, :deleted, :boolean, default: false)

    Ticket.where(deleted: nil).update_all(deleted: false)
    change_column(:tickets, :deleted, :boolean, default: false)

    BankAccount.where(deleted: nil).update_all(deleted: false)
    change_column(:bank_accounts, :deleted, :boolean, default: false)

    Campaign.where(deleted: nil).update_all(deleted: false)
    change_column(:campaigns, :deleted, :boolean, default: false)

    Card.where(deleted: nil).update_all(deleted: false)
    change_column(:cards, :deleted, :boolean, default: false)

    CustomFieldMaster.where(deleted: nil).update_all(deleted: false)
    change_column(:custom_field_masters, :deleted, :boolean, default: false)

    Event.where(deleted: nil).update_all(deleted: false)
    change_column(:events, :deleted, :boolean, default: false)

    SupporterNote.where(deleted: nil).update_all(deleted: false)
    change_column(:supporter_notes, :deleted, :boolean, default: false)

    Supporter.where(deleted: nil).update_all(deleted: false)
    change_column(:supporters, :deleted, :boolean, default: false)
  end

  def down
    change_column(:tag_masters, :deleted, :boolean)

    change_column(:ticket_levels, :deleted, :boolean)

    change_column(:tickets, :deleted, :boolean)

    change_column(:bank_accounts, :deleted, :boolean)

    change_column(:campaigns, :deleted, :boolean)

    change_column(:cards, :deleted, :boolean)

    change_column(:custom_field_masters, :deleted, :boolean)

    change_column(:events, :deleted, :boolean)

    change_column(:supporter_notes, :deleted, :boolean)

    change_column(:supporters, :deleted, :boolean)
  end
end
