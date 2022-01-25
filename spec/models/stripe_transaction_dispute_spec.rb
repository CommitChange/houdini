# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE
require 'rails_helper'

RSpec.describe StripeTransactionDispute, type: :model do
  it_behaves_like 'subtransaction paymentable', :stripedisp
  it {
    is_expected.to(have_one(:legacy_payment)
      .class_name('Payment')
      .through(:subtransaction_payment)
    )
  }

  it {
    is_expected.to delegate_method(:gross_amount).to(:legacy_payment)
  }

  it {
    is_expected.to delegate_method(:net_amount).to(:legacy_payment)
  }

  it {
    is_expected.to delegate_method(:fee_total).to(:legacy_payment)
  }

  describe '#created' do
    let(:payment) {instance_double('Payment')}
    let(:item) {
      item = described_class.new
      expect(item).to receive(:legacy_payment).and_return(payment)
      item
      
    }
    it {
      expect(payment).to receive(:date)
      item.created
    }
  end
end
