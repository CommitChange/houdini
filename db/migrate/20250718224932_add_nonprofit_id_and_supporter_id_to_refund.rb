class AddNonprofitIdAndSupporterIdToRefund < ActiveRecord::Migration[7.1]
  def change
    add_reference :refunds, :nonprofit
    add_reference :refunds, :supporter
  end
end
