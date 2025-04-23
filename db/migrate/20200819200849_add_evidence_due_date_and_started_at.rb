class AddEvidenceDueDateAndStartedAt < ActiveRecord::Migration
  def change
    add_column :stripe_disputes, :evidence_due_date, :datetime
    add_column :stripe_disputes, :started_at, :datetime
    StripeDispute.all.find_each do |s|
      s.object = s.object # rubocop:disable Lint/SelfAssignment
      s.save!
    end
  end
end
