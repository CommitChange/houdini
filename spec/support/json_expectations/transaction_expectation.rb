# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE


class JsonExpectations::TransactionExpectation
  include ActiveModel::AttributeAssignment
  attr_writer :expand
  attr_writer :nonprofit_houid, :supporter_houid, :transaction_houid
  attr_reader :subtransaction_expectation, :transaction_assignments



  def initialize(new_attributes)
    assign_attributes(new_attributes)
  end

  def gross_amount
    all_payments.map{|i| i.gross_amount}.sum
  end

  def fee_total
    all_payments.map{|i| i.fee_total}.sum
  end

  def charge_payment
    subtransaction_expectation.charge_payment
  end

  def additional_payments
    subtransaction_expectation.additional_payments
  end

  def all_payments
    subtransaction_expectation.all_payments
  end

  def created
    charge_payment.created
  end

  def net_amount
    gross_amount + fee_total
  end

  def nonprofit_houid
    @nonprofit_houid || match_houid(:np)
  end

  def transaction_houid
    @transaction_houid || match_houid(:trx)
  end

  def supporter_houid
    @supporter_houid || match_houid(:supp)
  end

  def subtransaction_expectation=(args={})
    @subtransaction_expectation = build_subtransaction_expectation(args)
  end

  def ordered_payment_expectations
    subtransaction_expectation.ordered_payment_expectations
  end

  def build_subtransaction_expectation(args={})
    ::JsonExpectations::SubtransactionExpectation.new(transaction_expectation: self, **args)
  end

  def transaction_assignments=(trx_assignments)
    @transaction_assignments = trx_assignments.map{|i| self.build_trx_assignment(i)}
  end

  def build_trx_assignment(args={})
    ::JsonExpectations::TrxAssignmentExpectation.new(transaction_expectation: self, **args)
  end

  def expand
    @expand || ['supporter', 'payments']
  end

  def output
    output = {
    'object' => 'transaction',
    'id' => transaction_houid,
    'created' => created.to_i,
    'amount' => {
      'cents' => gross_amount,
      'currency' => 'usd'
    },
    'nonprofit' => nonprofit_houid,
    
    subtransaction: subtransaction_expectation.output,
    payments: ordered_payment_expectations.map{|i| i.output(!expand.include?('payments'))},

    transaction_assignments: transaction_assignments.map{|i| i.output}
    }
    if expand.include? 'supporter'
    
      output = output.merge(supporter: {
        id: supporter_houid
      })
    else
      output = output.merge(supporter: supporter_houid)
    end
    output
  end

  
end