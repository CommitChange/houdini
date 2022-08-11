# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later

module UpdateDisputes

  def self.disburse_all_with_payments(payment_ids)
    DisputeTransaction.where("payment_id IN (?)", payment_ids).update_all(
      disbursed:true, 
      updated_at:Time.current
    )
  end
end
