class AddDefaultFeeCoverage < ActiveRecord::Migration
  def change
    add_column :misc_event_infos, :default_fee_coverage, :string, default: nil, nullable: true
    add_column :misc_campaign_infos, :default_fee_coverage, :string, default: nil, nullable: true
    add_column :miscellaneous_np_infos, :default_fee_coverage, :string, default: nil, nullable: true
  end
end
