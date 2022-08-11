# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class AddCurrencyToNonprofit < ActiveRecord::Migration
  def change
    add_column :nonprofits, :currency, :string, default: Settings.intntl.currencies[0]
  end
end
