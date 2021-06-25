class CreateFeeEras < ActiveRecord::Migration
  def change
    create_table :fee_eras do |t|
      t.datetime :start_time
      t.datetime :end_time

      t.string :local_country
      t.decimal :international_surcharge_fee

      t.boolean :refund_stripe_fee, default: false

      t.timestamps null: false
    end
  end
end
