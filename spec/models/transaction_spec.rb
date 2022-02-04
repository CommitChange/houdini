# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

RSpec.describe Transaction, type: :model do
  it_behaves_like 'an houidable entity', :trx

  it {
    is_expected.to(belong_to(:supporter))
  }

  it {
    is_expected.to(have_one(:nonprofit).through(:supporter))
  }
  
  it {
    is_expected.to(have_one(:subtransaction))
  }

  it {
    is_expected.to(have_many(:transaction_assignments).inverse_of('trx'))
  }

  it {
    is_expected.to(have_many(:donations)
      .through(:transaction_assignments)
      .source(:assignable)
      .class_name("ModernDonation")
    )
  }

  it {
    is_expected.to(have_many(:object_events))
  }

  it {
    is_expected.to(have_many(:payments).through(:subtransaction).source(:subtransaction_payments).class_name('SubtransactionPayment'))
  }

  describe 'validation' do
    it {is_expected.to validate_presence_of(:supporter)}
  end

  describe 'houid is created' do
    subject { Transaction.create(supporter:create(:supporter))}
    it {is_expected.to have_attributes(houid: match_houid('trx'))}
  end
end
