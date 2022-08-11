# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddCardTokenToTicket < ActiveRecord::Migration
  def up
    add_column :tickets, :source_token_id, 'uuid'
  end

  def down
    remove_column :tickets, :source_token_id
  end
end
