# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

class JsonExpectations::PaymentExpectation
  include ActiveModel::AttributeAssignment
  
  attr_accessor :houid, :object, :subtransaction_expectation, :gross_amount, :fee_total, :flatten
  attr_writer :created

  def initialize(new_attributes)
    assign_attributes(new_attributes)
  end

  def net_amount
    gross_amount + fee_total
  end

  def transaction_expectation
    @transaction_expectation || subtransaction_expectation.transaction_expectation
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

  def subtransaction_houid
    subtransaction_expectation.houid
  end
  
  def transaction_expectation=(args={})
    @transaction_expectation = ::JsonExpectations::TransactionExpectation.new(payments: args[:payments].merge(self), **args)
  end

  def created
    @created || Time.current
  end

  def output(flatten=false)
    flatten ? 
      houid : {
        supporter: supporter_houid,
        nonprofit: nonprofit_houid,
        'created' => created.to_i,
        transaction: transaction_houid,
        subtransaction: subtransaction_houid,
        'fee_total' => {
          'cents' => fee_total,
          'currency' => 'usd'
        },
        'gross_amount' => {
          'cents' => gross_amount,
          'currency' => 'usd'
        },
        'net_amount' => {
          'cents' => net_amount,
          'currency' => 'usd'
        },
        'id' => houid,
        type: 'payment',
        object: object
      }
  end
end