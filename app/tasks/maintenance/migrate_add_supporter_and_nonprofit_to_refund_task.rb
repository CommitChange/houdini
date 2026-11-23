# frozen_string_literal: true

module Maintenance
  class MigrateAddSupporterAndNonprofitToRefundTask < MaintenanceTasks::Task
    def collection
      # Collection to be iterated over
      # Must be Active Record Relation or Array
      Refund.where(supporter_id: nil).or(Refund.where(nonprofit_id: nil))
    end

    def process(element)
      # The work to be done in a single iteration of the task.
      # This should be idempotent, as the same element may be processed more
      # than once if the task is interrupted and resumed.
      charge = element.charge
      if charge&.nonprofit_id || charge&.supporter_id
        element.update(nonprofit_id: charge.nonprofit_id, supporter_id: charge.supporter_id)
      end
    end

    def count
      # Optionally, define the number of rows that will be iterated over
      # This is used to track the task's progress
    end
  end
end
