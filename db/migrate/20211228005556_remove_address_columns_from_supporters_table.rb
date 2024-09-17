class RemoveAddressColumnsFromSupportersTable < ActiveRecord::Migration
  def change
    remove_column :supporters, :address
    remove_column :supporters, :city
    remove_column :supporters, :state_code
    remove_column :supporters, :zip_code
    remove_column :supporters, :country
  end
end
