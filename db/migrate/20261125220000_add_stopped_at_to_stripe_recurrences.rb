class AddStoppedAtToStripeRecurrences < ActiveRecord::Migration[7.1]
  def change
    change_table :stripe_recurrences, bulk: true do |t|
      t.datetime :stopped_at, comment: "When Slipflow stopped charging this gift on its own; null while it runs. A donor's or nonprofit's cancel is on the recurring donation, not here"
      t.string :stop_reason, comment: "Why Slipflow stopped: declined_three_times (three declines in a row), first_payment_refunded or first_payment_disputed"
      t.check_constraint "(stopped_at IS NULL) = (stop_reason IS NULL)", name: "stripe_recurrences_stop_reason_when_stopped"
      t.check_constraint "stop_reason IN ('declined_three_times', 'first_payment_refunded', 'first_payment_disputed')", name: "stripe_recurrences_stop_reason_known"
    end
  end
end
