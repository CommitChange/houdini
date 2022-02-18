class JsonExpectations::TrxAssignmentExpectation
  attr_accessor :houid, :object, :created, :transaction_expectation, :other_attributes
  attr_writer :amount
  include ActiveModel::AttributeAssignment

  def initialize(new_attributes)
    assign_attributes(new_attributes)
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

  def amount
    @transaction_expectation.gross_amount
  end

  def output
    {
      supporter: supporter_houid,
      nonprofit: nonprofit_houid,
      transaction: transaction_houid,
      'object' => 'donation',
      'amount' => {
        'cents' => amount,
        'currency' => 'usd'
      },
      id: houid,
    }.merge(other_attributes)
  end
end