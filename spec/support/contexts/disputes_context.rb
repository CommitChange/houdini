RSpec.shared_context :disputes_context do
  around(:each) do |example|
    StripeMock.start
      example.run
    StripeMock.stop
  end

  let(:dispute_time) { Time.at(1596429794)}

  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:nonprofit) { force_create(:nonprofit)}
  let(:supporter) { force_create(:supporter, nonprofit: nonprofit)}
  let(:json) do
    event_json['data']['object']
  end

  let(:dispute) { obj.dispute }
  let(:dispute_transactions) { dispute.dispute_transactions }

  # we reload this because we'll get the older version if we don't
  let(:original_payment) { 
    obj.dispute.original_payment.reload
    obj.dispute.original_payment

  }

  let(:withdrawal_transaction) {dispute.dispute_transactions.order("date").first}
  let(:withdrawal_payment) {withdrawal_transaction.payment}
  let(:reinstated_transaction) {dispute.dispute_transactions.order("date").second}
  let(:reinstated_payment) {reinstated_transaction.payment}

  let(:charge) { 
      transaction.ordered_payments.last.legacy_payment.charge
    }
end

RSpec.shared_context :disputes_specs do
  before(:each) do
    allow(JobQueue).to receive(:queue)
  end
  
  all_events = [:created, :updated, :funds_reinstated, :funds_withdrawn, :won, :lost]

    
  it 'has correct events in order' do
    valid_events.each do |t|
    
      job_type = ('JobTypes::Dispute' + t.to_s.camelize + "Job").constantize
      expect(JobQueue).to have_received(:queue).with(
      job_type, dispute).ordered
    end
  end

  it 'does not have invalid events' do 
    invalid_events = all_events - valid_events
    invalid_events.each do |t|
      job_type = ('JobTypes::Dispute' + t.to_s.camelize + "Job").constantize
      expect(JobQueue).to_not have_received(:queue).with(
      job_type)
    end
  end

  it 'has valid activities' do 
    valid_events.each do |t|
      dispute_kind = "Dispute" + t.to_s.camelize
      case t
      when :funds_withdrawn
        expect(withdrawal_transaction.payment.activities.where(kind: dispute_kind).count).to eq 1
      when :funds_reinstated
        expect(reinstated_transaction.payment.activities.where(kind: dispute_kind).count).to eq 1
      else
        expect(dispute.activities.where(kind: dispute_kind).count).to eq 1
      end
    end
  end

  it 'does not have invalid activities' do 
    invalid_events = all_events - valid_events
    invalid_events.each do |t|
      dispute_kind = "Dispute" + t.to_s.camelize
      case t
      when :funds_withdrawn
        if (withdrawal_transaction)
          expect(withdrawal_transaction.payment.activities.where(kind: dispute_kind)).to be_empty, "#{dispute_kind} should not have been here."
        end
      when :funds_reinstated
        if (reinstated_transaction)
          expect(reinstated_transaction.payment.activities.where(kind: dispute_kind)).to be_empty, "#{dispute_kind} should not have been here."
        end
      else
        #byebug if dispute_kind == "DisputeUpdated" && dispute.activities.where(kind: dispute_kind).any?
        expect(dispute.activities.where(kind: dispute_kind)).to be_empty, "#{dispute_kind} should not have been here."
      end
    end
  end
end

RSpec.shared_context :dispute_created_context do 
  include_context :disputes_context do 

    let(:event_json) do 
      event_json = StripeMock.mock_webhook_event('charge.dispute.created')
      stripe_helper.upsert_stripe_object(:dispute, event_json['data']['object'])
      event_json
    end

    let!(:transaction) {
      Timecop.freeze(dispute_time - 1.day) do 
        create(:transaction_for_stripe_dispute_of_80000,
          supporter:supporter,
          )
      end
    }

    let(:charge) { 
      transaction.ordered_payments.last.legacy_payment.charge
    }
  end
end

RSpec.shared_context :dispute_created_specs do
  include_context :dispute_created_context
  include_context :disputes_specs

  it 'has status of needs_response' do 
    expect(obj.status).to eq 'needs_response'
  end

  it 'has reason of duplicate' do 
    expect(obj.reason).to eq 'duplicate'
  end

  it 'has 0 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 0
  end

  it 'has a net_change of 0' do
    expect(obj.net_change).to eq 0
  end

  it 'has an amount of 80000' do
    expect(obj.amount).to eq 80000
  end

  it 'has a correct charge id ' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_05RsQX2eZvKYlo2C0FRTGSSA"
  end

  it 'has a started_at of Time.at(1596429794)' do
    expect(obj.started_at).to eq Time.at(1596429794)
  end

  it 'has a saved dispute' do 
    expect(dispute).to be_persisted
  end

  it 'has a dispute with 80000' do 
    expect(dispute.gross_amount).to eq 80000
  end

  it 'has a dispute with status of needs_response' do 
    expect(dispute.status).to eq "needs_response"
  end

  it 'has a dispute with reason of duplicate' do 
    expect(dispute.reason).to eq 'duplicate'
  end

  it 'has a dispute with started_at of Time.at(1596429794)' do
    expect(dispute.started_at).to eq Time.at(1596429794)
  end

  it 'has no dispute transactions' do 
    expect(dispute_transactions).to eq []
  end

  describe 'transaction' do
    subject(:transaction_result) do
      ApiNew::TransactionsController.render('api_new/transactions/show', 
      assigns: {
        transaction: transaction,
        __expand: Controllers::ApiNew::JbuilderExpansions.set_expansions(
          'supporter',
          'subtransaction.payments',
          'transaction_assignments',
          'payments')
      })
    end

    describe 'result' do 
      include_context 'json results for transaction expectations'

      it {
        obj
            is_expected.to include_json(generate_transaction_json(
              nonprofit_houid: nonprofit.houid,
              supporter_houid: supporter.houid,
              transaction_houid: transaction.houid,
              subtransaction_expectation: {
                object: 'stripe_transaction',
                houid: match_houid(:stripetrx),
                charge_payment: {
                  object: 'stripe_transaction_charge',
                  houid: match_houid(:stripechrg),
                  gross_amount: 80000,
                  fee_total: 0,
                  created: Time.at(1596429794) - 1.day
                }
              },
    
              transaction_assignments: [
                {
                  object: 'donation',
                  houid: match_houid(:don),
                  other_attributes: {
                    designation: "Designation 1"
                  }
                }
              ]
    
            ))
          }
    end
  end

  describe 'object events' do
    include_context 'json results for transaction expectations'
    describe 'transaction.updated' do
      subject(:object_event_result) do
        obj
        ApiNew::ObjectEventsController.render('api_new/object_events/index', 
        assigns: {
          object_events: nonprofit.associated_object_events.event_types(['transaction.updated']).page
        })
      end

      it {
        # the transaction hasn't been updated so there's no need for an object event to be there
        is_expected.to include_json(data:[])
      }
    end

    
  end

  specify { expect(original_payment.refund_total).to eq 0 }

  let(:valid_events) { [:created]}
end

RSpec.shared_context :dispute_funds_withdrawn_context do 
  include_context :disputes_context do 

    let(:event_json) do 
      event_json = StripeMock.mock_webhook_event('charge.dispute.funds_withdrawn')
      stripe_helper.upsert_stripe_object(:dispute, event_json['data']['object'])
      event_json
    end

    let!(:transaction) {
      Timecop.freeze(dispute_time - 1.day) do 
      create(:transaction_for_stripe_dispute_of_80000,
        supporter:supporter)
      end
    }
    
  end
end

RSpec.shared_context :dispute_funds_withdrawn_specs do
  include_context :dispute_funds_withdrawn_context
  include_context :disputes_specs

  it 'has status of needs_response' do 
    expect(obj.status).to eq 'needs_response'
  end

  it 'has reason of duplicate' do 
    expect(obj.reason).to eq 'duplicate'
  end

  it 'has 1 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 1
  end

  it 'has a net_change of -81500' do
    expect(obj.net_change).to eq -81500
  end

  it 'has an amount of 80000' do
    expect(obj.amount).to eq 80000
  end

  it 'has a correct charge id ' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_05RsQX2eZvKYlo2C0FRTGSSA"
  end

  it 'has a started_at of Time.at(1596430555)' do
    expect(obj.started_at).to eq Time.at(1596429794)
  end

  describe "dispute" do
    subject { dispute }
    specify {expect(subject).to be_persisted }
    specify {expect(subject.gross_amount).to eq 80000 }
    specify {expect(subject.status).to eq "needs_response" }
    specify { expect(subject.reason).to eq 'duplicate' }
    specify { expect(subject.started_at).to eq Time.at(1596429794) }
  end

  it 'has one dispute transaction' do
    expect(dispute_transactions.count).to eq 1
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify {  expect(subject).to be_persisted }
    specify {  expect(subject.gross_amount).to eq -80000 }
    specify {  expect(subject.fee_total).to eq -1500 }
    specify {  expect(subject.stripe_transaction_id).to eq 'txn_1Y7pdnBCJIIhvMWmJ9KQVpfB' }
    specify {  expect(subject).to be_persisted }
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.net_amount).to eq -81500}
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
  end

  describe 'transaction' do
    subject(:transaction_result) do
      obj
      ApiNew::TransactionsController.render('api_new/transactions/show', 
      assigns: {
        transaction: transaction.reload,
        __expand: Controllers::ApiNew::JbuilderExpansions.set_expansions(
          'supporter',
          'subtransaction.payments',
          'transaction_assignments',
          'payments')
      })
    end

    describe 'result' do 
      include_context 'json results for transaction expectations'

      it {
            is_expected.to include_json(generate_transaction_json(
              nonprofit_houid: nonprofit.houid,
              supporter_houid: supporter.houid,
              transaction_houid: transaction.houid,
              subtransaction_expectation: {
                object: 'stripe_transaction',
                houid: match_houid(:stripetrx),
                charge_payment: {
                  object: 'stripe_transaction_charge',
                  houid: match_houid(:stripechrg),
                  gross_amount: 80000,
                  fee_total: 0,
                  created: dispute_time - 1.day
                },
                additional_payments: [
                  {
                    object: 'stripe_transaction_dispute',
                    houid: match_houid(:stripedisp),
                    gross_amount: -80000,
                    fee_total: -1500,
                    created: DateTime.new(2020, 8, 3, 4, 55, 55)
                  }
                ]
              },
    
              transaction_assignments: [
                {
                  object: 'donation',
                  houid: match_houid(:don),
                  other_attributes: {
                    designation: "Designation 1"
                  }
                }
              ]
    
            ))
          }
    end
  end

  describe 'object events' do
    include_context 'json results for transaction expectations'
    describe 'transaction.updated' do
      subject(:object_event_result) do
        obj
        ApiNew::ObjectEventsController.render('api_new/object_events/index', 
        assigns: {
          object_events: nonprofit.associated_object_events.event_types(['transaction.updated']).page
        })
      end

      it {
        
        # the transaction hasn't been updated so there's no need for an object event to be there
        is_expected.to include_json(data:[])
      }
    end

    describe 'other changes' do
      subject(:object_event_result) do
        obj
        ApiNew::ObjectEventsController.render('api_new/object_events/index', 
        assigns: {
          object_events: nonprofit.associated_object_events.event_types(['stripe_transaction_charge.updated', 'stripe_transaction_dispute.created', 'donation.updated']).page
        })
      end

      

      it {
        is_expected.to include_json(data:[
          generate_object_event_json(type: 'stripe_transaction_charge.updated', data: a_kind_of(Object)),
          generate_object_event_json(type: 'stripe_transaction_dispute.created', data: {
              
              nonprofit: nonprofit.houid,
              supporter: supporter.houid,
              transaction: transaction.houid,  
              id: match_houid(:stripedisp),
              fee_total: {cents: -1500} ,
              gross_amount: {cents: -80000},
              net_amount: {cents: -80000 + -1500}
            }),
          generate_object_event_json(type: 'donation.updated', 
          data: {
                          
            nonprofit: nonprofit.houid,
            supporter: supporter.houid,
            transaction: {
              id:transaction.houid,
              amount: {cents: 0}
            },
              
            id: match_houid(:don),
            amount: {cents: 0}
          })
        ])
      }
    end

    
  end

  specify { expect(original_payment.refund_total).to eq 80000 }

  let(:valid_events) { [:created, :funds_withdrawn]}
end

RSpec.shared_context :dispute_funds_reinstated_context do
  include_context :disputes_context
  let(:event_json) do
    event_json =StripeMock.mock_webhook_event('charge.dispute.funds_reinstated')
    stripe_helper.upsert_stripe_object(:dispute, event_json['data']['object'])
    event_json
  end
  let!(:transaction) {
      create(:transaction_for_stripe_dispute_of_80000, 
        supporter:supporter)
  }
end

RSpec.shared_context :dispute_funds_reinstated_specs do
  include_context :dispute_funds_reinstated_context
  include_context :disputes_specs

  it 'has status of under_review' do 
    expect(obj.status).to eq 'under_review'
  end

  it 'has reason of credit_not_processed' do 
    expect(obj.reason).to eq 'credit_not_processed'
  end

  it 'has 0 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 2
  end

  it 'has a net_change of 0' do
    expect(obj.net_change).to eq 0
  end

  it 'has an amount of 80000' do
    expect(obj.amount).to eq 80000
  end

  it 'has a correct charge id ' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7vFYBCJIIhvMWmsdRJWSw5"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_15RsQX2eZvKYlo2C0ERTYUIA"
  end

  it 'has a started_at of Time.at(1567603760)' do
    expect(obj.started_at).to eq Time.at(1567603760)
  end

  describe "dispute" do
    subject { dispute }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq 80000 }
    specify { expect(subject.status).to eq "under_review" }
    specify { expect(subject.reason).to eq 'credit_not_processed' }
    specify { expect(subject.started_at).to eq Time.at(1567603760)}
  end

  it 'has two dispute transactions' do
    expect(dispute_transactions.count).to eq 2
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify {  expect(subject).to be_persisted }
    specify {  expect(subject.gross_amount).to eq -80000 }
    specify {  expect(subject.fee_total).to eq -1500 }
    specify {  expect(subject.stripe_transaction_id).to eq 'txn_1Y75JVBCJIIhvMWmsnGK1JLD' }
    specify { expect(subject.date).to eq DateTime.new(2019,9,4,13,29,20)}
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.net_amount).to eq -81500}
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2019,9,4,13,29,20)}
  end


  describe 'has a reinstated_transaction' do
    subject{ reinstated_transaction }
    specify {  expect(subject).to be_persisted }
    specify {  expect(subject.gross_amount).to eq 80000 }
    specify {  expect(subject.fee_total).to eq 1500 }
    specify { expect(subject.net_amount).to eq 81500}
    specify {  expect(subject.stripe_transaction_id).to eq 'txn_1Y71X0BCJIIhvMWmMmtTY4m1' }
    specify { expect(subject.date).to eq DateTime.new(2019,11,28,21,43,10)}
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a reinstated_payment' do
    subject { reinstated_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq 80000}
    specify { expect(subject.fee_total).to eq 1500}
    specify { expect(subject.kind).to eq 'DisputeReversed'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2019,11,28,21,43,10)}
  end

  describe 'transaction' do
    subject(:transaction_result) do
      obj
      ApiNew::TransactionsController.render('api_new/transactions/show', 
      assigns: {
        transaction: transaction.reload,
        __expand: Controllers::ApiNew::JbuilderExpansions.set_expansions(
          'supporter',
          'subtransaction.payments',
          'transaction_assignments',
          'payments')
      })
    end

    describe 'result' do 
      include_context 'json results for transaction expectations'

      it {
            is_expected.to include_json(generate_transaction_json(
              nonprofit_houid: nonprofit.houid,
              supporter_houid: supporter.houid,
              transaction_houid: transaction.houid,
              subtransaction_expectation: {
                object: 'stripe_transaction',
                houid: match_houid(:stripetrx),
                charge_payment: {
                  object: 'stripe_transaction_charge',
                  houid: match_houid(:stripechrg),
                  gross_amount: 80000,
                  fee_total: 0,
                  created: charge.created_at
                },
                additional_payments: [
                  {
                    object: 'stripe_transaction_dispute',
                    houid: match_houid(:stripedisp),
                    gross_amount: -80000,
                    fee_total: -1500,
                    created: DateTime.new(2019,9,4,13,29,20)
                  },
                  {
                    object: 'stripe_transaction_dispute_reversal',
                    houid: match_houid(:stripedisprvrs),
                    gross_amount: 80000,
                    fee_total: 1500,
                    created: DateTime.new(2019,11,28,21,43,10)
                  }
                ]
              },
    
              transaction_assignments: [
                {
                  object: 'donation',
                  houid: match_houid(:don),
                  other_attributes: {
                    designation: "Designation 1"
                  }
                }
              ]
    
            ))
          }
    end

    describe 'object events' do
      include_context 'json results for transaction expectations'
      describe 'transaction.updated' do
        subject(:object_event_result) do
          obj
          ApiNew::ObjectEventsController.render('api_new/object_events/index', 
          assigns: {
            object_events: nonprofit.associated_object_events.event_types(['transaction.updated']).page
          })
        end
  
        it {
          
          # the transaction hasn't been updated so there's no need for an object event to be there
          is_expected.to include_json(data:[])
        }
      end
  
      describe 'other changes' do
        subject(:object_event_result) do
          obj
          ApiNew::ObjectEventsController.render('api_new/object_events/index', 
          assigns: {
            object_events: nonprofit.associated_object_events.event_types(['stripe_transaction_charge.updated', 'stripe_transaction_dispute.created', 'donation.updated']).page
          })
        end
  
        
  
        it {
          is_expected.to include_json(data:[
            generate_object_event_json(type: 'stripe_transaction_dispute_reversal.created', data: 
            {
                
              nonprofit: nonprofit.houid,
              supporter: supporter.houid,
              transaction: transaction.houid,  
              id: match_houid(:stripedisprvrs),
              fee_total: {cents: 1500} ,
              gross_amount: {cents: 80000},
              net_amount: {cents: 80000}
            }),
            generate_object_event_json(type: 'donation.updated', 
            data: {
                            
              nonprofit: nonprofit.houid,
              supporter: supporter.houid,
              transaction: {
                id:transaction.houid,
                amount: {cents: 800}
              },
                
              id: match_houid(:don),
              amount: {cents: 800}
            })
            generate_object_event_json(type: 'stripe_transaction_charge.updated', data: a_kind_of(Object)),
            generate_object_event_json(type: 'stripe_transaction_dispute.created', data: {
                
                nonprofit: nonprofit.houid,
                supporter: supporter.houid,
                transaction: transaction.houid,  
                id: match_houid(:stripedisp),
                fee_total: {cents: -1500} ,
                gross_amount: {cents: -80000},
                net_amount: {cents: -80000 + -1500}
              }),
            generate_object_event_json(type: 'donation.updated', 
            data: {
                            
              nonprofit: nonprofit.houid,
              supporter: supporter.houid,
              transaction: {
                id:transaction.houid,
                amount: {cents: 0}
              },
                
              id: match_houid(:don),
              amount: {cents: 0}
            })
          ])
        }
      end
  
      
    end
  end

  specify { expect(original_payment.refund_total).to eq 0 }

  let(:valid_events) { [:created, :funds_withdrawn, :funds_reinstated]}
end

RSpec.shared_context :dispute_lost_context do
  include_context :disputes_context
  let(:event_json) do
    event_json =StripeMock.mock_webhook_event('charge.dispute.closed-lost')
    stripe_helper.upsert_stripe_object(:dispute, event_json['data']['object'])
    event_json
  end
  let!(:transaction) {
    Timecop.freeze(dispute_time - 1.day) do 
      create(:transaction_for_stripe_dispute_of_80000, 
        supporter:supporter)
    end
  }
end

RSpec.shared_context :dispute_lost_specs do
  include_context :dispute_lost_context
  include_context :disputes_specs

  it 'has status of under_review' do 
    expect(obj.status).to eq 'lost'
  end

  it 'has reason of credit_not_processed' do 
    expect(obj.reason).to eq 'duplicate'
  end

  it 'has 1 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 1
  end

  it 'has a net_change of -81500' do
    expect(obj.net_change).to eq -81500
  end

  it 'has an amount of 80000' do
    expect(obj.amount).to eq 80000
  end

  it 'has a correct charge id' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_05RsQX2eZvKYlo2C0FRTGSSA"
  end

  it 'has a started_at of Time.at(1596430555)' do 
    expect(obj.started_at).to eq  Time.at(1596429794)
  end

  describe "dispute" do
    subject { dispute }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq 80000 }
    specify { expect(subject.status).to eq "lost" }
    specify { expect(subject.reason).to eq 'duplicate' }
    specify { expect(subject.started_at).to eq Time.at(1596429794) }
  end

  it 'has 1 dispute transactions' do
    expect(dispute_transactions.count).to eq 1
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000 }
    specify { expect(subject.fee_total).to eq -1500 }
    specify { expect(subject.stripe_transaction_id).to eq 'txn_1Y7pdnBCJIIhvMWmJ9KQVpfB' }
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.net_amount).to eq -81500}
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
  end

  it 'has no reinstated transaction' do 
    expect(reinstated_transaction).to be_nil
  end

  let(:valid_events) { [:created, :funds_withdrawn, :lost]}
end

RSpec.shared_context :dispute_won_context do
  include_context :disputes_context
  let(:event_json) do
    event_json =StripeMock.mock_webhook_event('charge.dispute.closed-won')
    stripe_helper.upsert_stripe_object(:dispute, event_json['data']['object'])
    event_json
  end
  let!(:transaction) {
  
    create(:transaction_for_stripe_dispute_of_80000,
      supporter:supporter)
  }
end

RSpec.shared_context :dispute_won_specs do
  include_context :dispute_won_context
  include_context :disputes_specs

  it 'has status of won' do 
    expect(obj.status).to eq 'won'
  end

  it 'has reason of credit_not_processed' do 
    expect(obj.reason).to eq 'credit_not_processed'
  end

  it 'has 2 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 2
  end

  it 'has a net_change of 0' do
    expect(obj.net_change).to eq 0
  end

  it 'has an amount of 80000' do
    expect(obj.amount).to eq 80000
  end

  it 'has a correct charge id ' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7vFYBCJIIhvMWmsdRJWSw5"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_15RsQX2eZvKYlo2C0ERTYUIA"
  end
  
  it 'has a started_at of Time.at(1565008160)' do
    expect(obj.started_at).to eq Time.at(1565008160)
  end

  describe "dispute" do
    subject { dispute }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq 80000 }
    specify { expect(subject.status).to eq "won" }
    specify { expect(subject.reason).to eq 'credit_not_processed' }
    specify { expect(subject.started_at).to eq Time.at(1565008160) }
  end

  it 'has two dispute transactions' do
    expect(dispute_transactions.count).to eq 2
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify {  expect(subject).to be_persisted }
    specify {  expect(subject.gross_amount).to eq -80000 }
    specify {  expect(subject.fee_total).to eq -1500 }
    specify {  expect(subject.stripe_transaction_id).to eq 'txn_1Y75JVBCJIIhvMWmsnGK1JLD' }
    specify { expect(subject.date).to eq DateTime.new(2019,8,5,12,29,20)}
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.net_amount).to eq -81500 }
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2019,8,5,12,29,20)}
  end


  describe 'has a reinstated_transaction' do
    subject{ reinstated_transaction }
    specify {  expect(subject).to be_persisted }
    specify {  expect(subject.gross_amount).to eq 80000 }
    specify {  expect(subject.fee_total).to eq 1500 }
    specify {  expect(subject.stripe_transaction_id).to eq 'txn_1Y71X0BCJIIhvMWmMmtTY4m1' }
    specify { expect(subject.date).to eq DateTime.new(2019,10,29,20,43,10)}
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a reinstated_payment' do
    subject { reinstated_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq 80000}
    specify { expect(subject.fee_total).to eq 1500}
    specify { expect(subject.net_amount).to eq 81500 }
    specify { expect(subject.kind).to eq 'DisputeReversed'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2019,10,29,20,43,10)}
  end

  specify { expect(original_payment.refund_total).to eq 0 }

  let(:valid_events) { [:created, :funds_withdrawn, :funds_reinstated, :won]}
end

RSpec.shared_context :dispute_created_and_withdrawn_at_same_time_context do 
  include_context :disputes_context
  let(:event_json_created) do
    StripeMock.mock_webhook_event('charge.dispute.created-with-one-withdrawn')
  end

  let(:json_created) { event_json_created['data']['object']}

  let(:json_funds_withdrawn) {event_json_funds_withdrawn['data']['object']}

  let(:event_json_funds_withdrawn) do
    json = StripeMock.mock_webhook_event('charge.dispute.funds_withdrawn')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end

  let!(:transaction) {
    Timecop.freeze(dispute_time - 1.day) do 
      create(:transaction_for_stripe_dispute_of_80000, 
        supporter:supporter,
        )
    end
  }
end

RSpec.shared_context :dispute_created_and_withdrawn_at_same_time_specs do
  include_context :dispute_created_and_withdrawn_at_same_time_context
  include_context :disputes_specs

  it 'has status of needs_response' do 
    expect(obj.status).to eq 'needs_response'
  end

  it 'has reason of duplicate' do 
    expect(obj.reason).to eq 'duplicate'
  end

  it 'has 1 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 1
  end

  it 'has a net_change of -81500' do
    expect(obj.net_change).to eq -81500
  end

  it 'has an amount of 80000' do
    expect(obj.amount).to eq 80000
  end

  it 'has a correct charge id ' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_05RsQX2eZvKYlo2C0FRTGSSA"
  end


  it 'has a started_at of Time.at(1596430555)' do 
    expect(obj.started_at).to eq Time.at(1596429794)
  end

  describe "dispute" do
    subject { dispute }
    specify {expect(subject).to be_persisted }
    specify {expect(subject.gross_amount).to eq 80000 }
    specify {expect(subject.status).to eq "needs_response" }
    specify { expect(subject.reason).to eq 'duplicate' }
    specify { expect(subject.started_at).to eq Time.at(1596429794)}
  end

  it 'has one dispute transaction' do
    expect(dispute_transactions.count).to eq 1
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify {  expect(subject).to be_persisted }
    specify {  expect(subject.gross_amount).to eq -80000 }
    specify {  expect(subject.fee_total).to eq -1500 }
    specify { expect(subject.net_amount).to eq -81500}
    specify {  expect(subject.stripe_transaction_id).to eq 'txn_1Y7pdnBCJIIhvMWmJ9KQVpfB' }
    specify {  expect(subject).to be_persisted }
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
  end

  it 'has only added one payment' do
    obj
    expect(Payment.count).to eq 2 #one for charge, one for DisputeTransaction
  end

  it 'has only one dispute transaction' do 
    obj
    expect(DisputeTransaction.count).to eq 1
  end

  specify { expect(original_payment.refund_total).to eq 80000 }

  let(:valid_events) { [:created, :funds_withdrawn]}
end

RSpec.shared_context :dispute_created_and_withdrawn_in_order_context do 
  include_context :dispute_created_and_withdrawn_at_same_time_context
  let(:event_json_created) do
    json = StripeMock.mock_webhook_event('charge.dispute.created')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end

  let(:json_created) { event_json_created['data']['object']}

  let(:json_funds_withdrawn) {event_json_funds_withdrawn['data']['object']}

  let(:event_json_funds_withdrawn) do
    json = StripeMock.mock_webhook_event('charge.dispute.funds_withdrawn')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end

  let!(:transaction) {
    Timecop.freeze(dispute_time - 1.day) do 
      create(:transaction_for_stripe_dispute_of_80000,
        supporter:supporter,
        )
    end
  }
end

RSpec.shared_context :dispute_created_and_withdrawn_in_order_specs do
  include_context :dispute_created_and_withdrawn_in_order_context
  include_context :disputes_specs

  it 'has status of needs_response' do 
    expect(obj.status).to eq 'needs_response'
  end

  it 'has reason of duplicate' do 
    expect(obj.reason).to eq 'duplicate'
  end

  it 'has 1 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 1
  end

  it 'has a net_change of -81500' do
    expect(obj.net_change).to eq -81500
  end

  it 'has an amount of 80000' do
    expect(obj.amount).to eq 80000
  end

  it 'has a correct charge id ' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_05RsQX2eZvKYlo2C0FRTGSSA"
  end


  it 'has a started_at of Time.at(1596430555)' do 
    expect(obj.started_at).to eq Time.at(1596429794)
  end

  describe "dispute" do
    subject { dispute }
    specify {expect(subject).to be_persisted }
    specify {expect(subject.gross_amount).to eq 80000 }
    specify {expect(subject.status).to eq "needs_response" }
    specify { expect(subject.reason).to eq 'duplicate' }
    specify { expect(subject.started_at).to eq Time.at(1596429794)}
  end

  it 'has one dispute transaction' do
    expect(dispute_transactions.count).to eq 1
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify {  expect(subject).to be_persisted }
    specify {  expect(subject.gross_amount).to eq -80000 }
    specify {  expect(subject.fee_total).to eq -1500 }
    specify { expect(subject.net_amount).to eq -81500}
    specify {  expect(subject.stripe_transaction_id).to eq 'txn_1Y7pdnBCJIIhvMWmJ9KQVpfB' }
    specify {  expect(subject).to be_persisted }
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
  end

  it 'has only added one payment' do
    obj
    expect(Payment.count).to eq 2 #one for charge, one for DisputeTransaction
  end

  it 'has only one dispute transaction' do 
    obj
    expect(DisputeTransaction.count).to eq 1
  end

  specify { expect(original_payment.refund_total).to eq 80000 }

  let(:valid_events) { [:created, :funds_withdrawn]}
end

RSpec.shared_context :dispute_created_withdrawn_and_lost_in_order_context do 
  include_context :disputes_context
  let(:event_json_created) do
    json = StripeMock.mock_webhook_event('charge.dispute.created')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end

  let(:json_created) { event_json_created['data']['object']}

  let(:event_json_funds_withdrawn) do
    json = StripeMock.mock_webhook_event('charge.dispute.funds_withdrawn')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end

  let(:json_funds_withdrawn) {event_json_funds_withdrawn['data']['object']}

  let(:event_json_lost) do
    json = StripeMock.mock_webhook_event('charge.dispute.closed-lost')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end
  
  let(:json_lost) do
    event_json_lost['data']['object']
  end

  let!(:transaction) {
    Timecop.freeze(dispute_time - 1.day) do 
      create(:transaction_for_stripe_dispute_of_80000,
        supporter:supporter,
        )
    end
  }
end

RSpec.shared_context :dispute_created_withdrawn_and_lost_in_order_specs do 
  include_context :dispute_created_withdrawn_and_lost_in_order_context
  include_context :disputes_specs

  it 'has status of lost' do 
    expect(obj.status).to eq 'lost'
  end

  it 'has reason of duplicate' do 
    expect(obj.reason).to eq 'duplicate'
  end

  it 'has 1 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 1
  end

  it 'has a net_change of -81500' do
    expect(obj.net_change).to eq -81500
  end

  it 'has an amount of 80000' do
    expect(obj.amount).to eq 80000
  end

  it 'has a correct charge id' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_05RsQX2eZvKYlo2C0FRTGSSA"
  end

  it 'has a started_at of Time.at(1596429794)' do 
    expect(obj.started_at).to eq Time.at(1596429794)
  end

  describe "dispute" do
    subject { dispute }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq 80000 }
    specify { expect(subject.status).to eq "lost" }
    specify { expect(subject.reason).to eq 'duplicate' }
    specify { expect(subject.started_at).to eq Time.at(1596429794)}
  end

  it 'has 1 dispute transactions' do
    expect(dispute_transactions.count).to eq 1
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000 }
    specify { expect(subject.fee_total).to eq -1500 }
    specify { expect(subject.stripe_transaction_id).to eq 'txn_1Y7pdnBCJIIhvMWmJ9KQVpfB' }
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.net_amount).to eq -81500}
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
  end

  it 'has no reinstated transaction' do 
    expect(reinstated_transaction).to be_nil
  end

  specify { expect(original_payment.refund_total).to eq 80000 }

  let(:valid_events) { [:created, :funds_withdrawn, :lost]}
end

RSpec.shared_context :dispute_created_with_withdrawn_and_lost_in_order_context do
  
  include_context :dispute_created_withdrawn_and_lost_in_order_context

  let(:event_json_created) do
    json = StripeMock.mock_webhook_event('charge.dispute.created-with-one-withdrawn')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end
end

RSpec.shared_context :dispute_created_with_withdrawn_and_lost_in_order_specs do
  include_context :dispute_created_with_withdrawn_and_lost_in_order_context
  include_context :disputes_specs

  it 'has status of lost' do 
    expect(obj.status).to eq 'lost'
  end

  it 'has reason of duplicate' do 
    expect(obj.reason).to eq 'duplicate'
  end

  it 'has 1 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 1
  end

  it 'has a net_change of -81500' do
    expect(obj.net_change).to eq -81500
  end

  it 'has an amount of 80000' do
    expect(obj.amount).to eq 80000
  end

  it 'has a correct charge id' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_05RsQX2eZvKYlo2C0FRTGSSA"
  end

  it 'has a started_at of Time.at(1596429794)' do 
    expect(obj.started_at).to eq Time.at(1596429794)
  end

  describe "dispute" do
    subject { dispute }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq 80000 }
    specify { expect(subject.status).to eq "lost" }
    specify { expect(subject.reason).to eq 'duplicate' }
    specify { expect(subject.started_at).to eq Time.at(1596429794)}
  end

  it 'has 1 dispute transactions' do
    expect(dispute_transactions.count).to eq 1
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000 }
    specify { expect(subject.fee_total).to eq -1500 }
    specify { expect(subject.stripe_transaction_id).to eq 'txn_1Y7pdnBCJIIhvMWmJ9KQVpfB' }
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.net_amount).to eq -81500}
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
  end

  it 'has no reinstated transaction' do 
    expect(reinstated_transaction).to be_nil
  end

  specify { expect(original_payment.refund_total).to eq 80000 }

  let(:valid_events) { [:created, :funds_withdrawn, :lost]}
end

RSpec.shared_context :dispute_lost_created_and_funds_withdrawn_at_same_time_context do
  
  include_context :disputes_context
  let(:event_json_created) do
    json = StripeMock.mock_webhook_event('charge.dispute.created')
    json
  end

  let(:json_created) { event_json_created['data']['object']}

  let(:event_json_funds_withdrawn) do
    json = StripeMock.mock_webhook_event('charge.dispute.funds_withdrawn')
    json
  end

  let(:json_funds_withdrawn) {event_json_funds_withdrawn['data']['object']}

  let(:event_json_lost) do
    json = StripeMock.mock_webhook_event('charge.dispute.closed-lost')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end
  
  let(:json_lost) do
    event_json_lost['data']['object']
  end

  let!(:transaction) {
    Timecop.freeze(dispute_time - 1.day) do 
      create(:transaction_for_stripe_dispute_of_80000,
        supporter:supporter,
        )
    end
  }

  let(:event_json_created) do
    json = StripeMock.mock_webhook_event('charge.dispute.created-with-one-withdrawn')
    json
  end
end

RSpec.shared_context :dispute_lost_created_and_funds_withdrawn_at_same_time_spec do
  include_context :dispute_lost_created_and_funds_withdrawn_at_same_time_context
  include_context :disputes_specs

  it 'has status of lost' do 
    expect(obj.status).to eq 'lost'
  end

  it 'has reason of duplicate' do 
    expect(obj.reason).to eq 'duplicate'
  end

  it 'has 1 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 1
  end

  it 'has a net_change of -81500' do
    expect(obj.net_change).to eq -81500
  end

  it 'has an amount of 80000' do
    expect(obj.amount).to eq 80000
  end

  it 'has a correct charge id' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_05RsQX2eZvKYlo2C0FRTGSSA"
  end

  it 'has a started_at of Time.at(1596429794)' do 
    expect(obj.started_at).to eq Time.at(1596429794)
  end

  describe "dispute" do
    subject { dispute }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq 80000 }
    specify { expect(subject.status).to eq "lost" }
    specify { expect(subject.reason).to eq 'duplicate' }
    specify { expect(subject.started_at).to eq Time.at(1596429794)}
  end

  it 'has 1 dispute transactions' do
    expect(dispute_transactions.count).to eq 1
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000 }
    specify { expect(subject.fee_total).to eq -1500 }
    specify { expect(subject.stripe_transaction_id).to eq 'txn_1Y7pdnBCJIIhvMWmJ9KQVpfB' }
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -80000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.net_amount).to eq -81500}
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
  end

  it 'has no reinstated transaction' do 
    expect(reinstated_transaction).to be_nil
  end

  specify { expect(original_payment.refund_total).to eq 80000 }

  let(:valid_events) { [:created, :funds_withdrawn, :lost]}
end

RSpec.shared_context :__dispute_with_two_partial_disputes_withdrawn_at_same_time_context do
  include_context :disputes_context
  let(:event_json_dispute_partial1) do
    json = StripeMock.mock_webhook_event('charge.dispute.created-with-one-withdrawn--partial1')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end

  let(:json_partial1) { event_json_dispute_partial1['data']['object']}

  let(:event_json_dispute_partial2) do
    json = StripeMock.mock_webhook_event('charge.dispute.created-with-one-withdrawn--partial2')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end

  let(:json_partial2) {event_json_dispute_partial2['data']['object']}

  let!(:transaction) {
    Timecop.freeze(dispute_time - 1.day) do 
      create(:transaction_for_stripe_dispute_of_80000,
        supporter:supporter,
        )
    end
  }

  specify { expect(original_payment.refund_total).to eq 70000 }
end

RSpec.shared_context :dispute_with_two_partial_disputes_withdrawn_at_same_time_spec__partial1 do
  include_context :__dispute_with_two_partial_disputes_withdrawn_at_same_time_context
  include_context :disputes_specs

  it 'has status of needs_response' do 
    expect(obj.status).to eq 'needs_response'
  end

  it 'has reason of duplicate' do 
    expect(obj.reason).to eq 'duplicate'
  end

  it 'has 1 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 1
  end

  it 'has a net_change of -41500' do
    expect(obj.net_change).to eq -41500
  end

  it 'has an amount of 40000' do
    expect(obj.amount).to eq 40000
  end

  it 'has a correct charge id' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_05RsQX2eZvKYlo2C0FRTGSSA"
  end

  it 'has a started_at of Time.at(1596429794)' do
    expect(obj.started_at).to eq Time.at(1596429794)
  end

  describe "dispute" do
    subject { dispute }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq 40000 }
    specify { expect(subject.status).to eq "needs_response" }
    specify { expect(subject.reason).to eq 'duplicate' }
    specify { expect(subject.started_at).to eq Time.at(1596429794)}
  end

  it 'has 1 dispute transactions' do
    expect(dispute_transactions.count).to eq 1
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -40000 }
    specify { expect(subject.fee_total).to eq -1500 }
    specify { expect(subject.stripe_transaction_id).to eq 'txn_1Y7pdnBCJIIhvMWmJ9KQVpfB' }
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -40000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.net_amount).to eq -41500}
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 55)}
  end

  it 'has no reinstated transaction' do 
    expect(reinstated_transaction).to be_nil
  end

  let(:valid_events) { [:created, :funds_withdrawn]}
end

RSpec.shared_context :dispute_with_two_partial_disputes_withdrawn_at_same_time_spec__partial2 do
  include_context :__dispute_with_two_partial_disputes_withdrawn_at_same_time_context
  include_context :disputes_specs

  it 'has status of needs_response' do 
    expect(obj.status).to eq 'needs_response'
  end

  it 'has reason of duplicate' do 
    expect(obj.reason).to eq 'duplicate'
  end

  it 'has 1 balance transactions' do 
    expect(obj.balance_transactions.count).to eq 1
  end

  it 'has a net_change of -31500' do
    expect(obj.net_change).to eq -31500
  end

  it 'has an amount of 30000' do
    expect(obj.amount).to eq 30000
  end

  it 'has a correct charge id' do 
    expect(obj.stripe_charge_id).to eq "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"
  end

  it 'has a correct dispute id' do 
    expect(obj.stripe_dispute_id).to eq "dp_25RsQX2eZvKYlo2C0ZXCVBNM"
  end

  it 'has a started_at of Time.at(1596429794)' do
    expect(obj.started_at).to eq Time.at(1596429794)
  end

  describe "dispute" do
    subject { dispute }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq 30000 }
    specify { expect(subject.status).to eq "needs_response" }
    specify { expect(subject.reason).to eq 'duplicate' }
    specify { expect(subject.started_at).to eq Time.at(1596429794)}
  end

  it 'has 1 dispute transactions' do
    expect(dispute_transactions.count).to eq 1
  end

  describe 'has a withdrawal_transaction' do
    subject{ withdrawal_transaction }
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -30000 }
    specify { expect(subject.fee_total).to eq -1500 }
    specify { expect(subject.stripe_transaction_id).to eq 'txn_1Y7pdnBCJIIhvMWmJ9KQVpfB' }
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 56)}
    specify { expect(subject.disbursed).to eq false }
  end

  describe 'has a withdrawal_payment' do
    subject { withdrawal_payment}
    specify { expect(subject).to be_persisted }
    specify { expect(subject.gross_amount).to eq -30000}
    specify { expect(subject.fee_total).to eq -1500}
    specify { expect(subject.net_amount).to eq -31500}
    specify { expect(subject.kind).to eq 'Dispute'}
    specify { expect(subject.nonprofit).to eq supporter.nonprofit}
    specify { expect(subject.date).to eq DateTime.new(2020, 8, 3, 4, 55, 56)}
  end

  it 'has no reinstated transaction' do 
    expect(reinstated_transaction).to be_nil
  end

  let(:valid_events) { [:created, :funds_withdrawn]}
end

RSpec.shared_context :legacy_dispute_context do
  include_context :disputes_context 
  
  let(:json) do
    dispute
    event_json['data']['object']
  end

  let!(:dispute) {  dispute = force_create(:dispute,  stripe_dispute_id: event_json['data']['object']['id'], 
    is_legacy: true, 
    charge_id: 'ch_1Y7zzfBCJIIhvMWmSiNWrPAC') 
    dispute.dispute_transactions.create(gross_amount: -80000, disbursed: true, payment: force_create(:payment, gross_amount: -80000, fee_total: -1500, net_amount: -81500))
    dispute
  }
  
  let(:dispute_transactions) { dispute.dispute_transactions }

  # we reload this because we'll get the older version if we don't
  let(:original_payment) { 
    obj.dispute.original_payment.reload
    obj.dispute.original_payment
  }

  let(:withdrawal_transaction) {dispute.dispute_transactions.order("date").first}
  let(:withdrawal_payment) {withdrawal_transaction.payment}
  let(:reinstated_transaction) {dispute.dispute_transactions.order("date").second}
  let(:reinstated_payment) {reinstated_transaction.payment}

  let(:event_json) do
    json = StripeMock.mock_webhook_event('charge.dispute.funds_withdrawn')
    stripe_helper.upsert_stripe_object(:dispute, json['data']['object'])
    json
  end
end

RSpec.shared_context :legacy_dispute_specs do
  include_context :legacy_dispute_context
  include_context :disputes_specs 
  it 'has no Dispute.activities' do 
    dispute.reload
    expect(dispute.activities).to be_empty
  end

  let(:valid_events) { []}
end