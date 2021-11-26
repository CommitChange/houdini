class ChangeDefaultCountryOnSupporter < ActiveRecord::Migration
  def change
    change_column_default :supporters, :country, nil
  end
end
