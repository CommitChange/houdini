class CreateExportFormats < ActiveRecord::Migration
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :export_formats do |t|
      t.string :name, null: false
      t.string :date_format
      t.boolean :show_currency, default: true, null: false
      t.jsonb :custom_columns_and_values

      t.references :nonprofit, index: true, foreign_key: true, null: false
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
