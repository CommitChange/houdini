# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

describe 'transactions factories' do
  describe :transaction_base do
    it 'creates one payment' do
      create(:transaction_base)
      expect(Payment.count).to eq 1
    end

    it 'creates one Donation' do
      create(:transaction_base)
      expect(Donation.count).to eq 1
    end

    it 'creates one Nonprofit' do
      create(:transaction_base)
      expect(Nonprofit.count).to eq 1
    end

    it 'creates one Supporter' do
      create(:transaction_base)
      expect(Supporter.count).to eq 1
    end

    it 'creates one OffsitePayment' do 
      create(:transaction_base)
      expect(OffsitePayment.count).to eq 1
    end

    it 'creates one TransactionAssignment' do 
      create(:transaction_base)
      expect(TransactionAssignment.count).to eq 1
    end

    it 'creates one ModernDonation' do 
      create(:transaction_base)
      expect(ModernDonation.count).to eq 1
    end

    it 'creates one Subtransaction' do
      create(:transaction_base)
      expect(Subtransaction.count).to eq 1
    end

    it 'creates one OfflineTransaction' do
      create(:transaction_base)
      expect(OfflineTransaction.count).to eq 1
    end

    it 'creates one SubtransactionPayment' do
      create(:transaction_base)
      expect(SubtransactionPayment.count).to eq 1
    end

    it 'creates one OfflineTransactionCharge' do
      create(:transaction_base)
      expect(OfflineTransactionCharge.count).to eq 1
    end
    
  end
end