# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

class JsonExpectations::SubtransactionExpectation
  include ActiveModel::AttributeAssignment
  attr_accessor :houid, :object, :transaction_expectation, :charge_payment, :additional_payments
  attr_reader :charge_payment, :additional_payments
  attr_writer :created
  
  def initialize(new_attributes)
    assign_attributes(new_attributes)
  end


  def gross_amount
    all_payments.map{|i| i.gross_amount}.sum
  end

  def net_amount
    all_payments.map{|i| i.net_amount}.sum
  end

  def all_payments
    payments = [charge_payment]
    payments += additional_payments
  end

  def nonprofit_houid
    transaction_expectation.nonprofit_houid
  end

  def transaction_houid
    transaction_expectation.transaction_houid
  end

  def supporter_houid
    transaction_expectation.supporter_houid
  end
  
  def ordered_payment_expectations
    all_payments.sort_by{|i| i.created}.reverse
  end

  def charge_payment=(args={})
    @charge_payment = build_payment_expectation(args)
  end

  def created
    @created || Time.current
  end

  def additional_payments
    @additional_payments || []
  end

  def additional_payments=(payments=[])
    @additional_payments = payments.map{|i| build_payment_expectation(i)}
  end

  def build_payment_expectation(args={})
    ::JsonExpectations::PaymentExpectation.new(subtransaction_expectation: self, **args)
  end

  def output
    {
      'id' => houid,
      'type' => 'subtransaction',
      'object' => object,
      supporter: supporter_houid,
      nonprofit: nonprofit_houid,
      transaction: transaction_houid,
      'created' => created.to_i,
      'amount' => {
        'cents' => gross_amount,
        'currency' => 'usd'
      },
      'net_amount' => {
        'cents' => net_amount,
        'currency' => 'usd'
      },
      payments: ordered_payment_expectations.map{|i| i.output}
    }
  end
end