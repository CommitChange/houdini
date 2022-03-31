# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

describe 'transactions factories' do
  describe :transaction_base do
    it 'creates one payment' do
      build(:transaction_base, :generate_donation).save!
      expect(Payment.count).to eq 1
    end

    it 'creates one Donation' do
      build(:transaction_base, :generate_donation).save!
      expect(Donation.count).to eq 1
    end

  it 'creates one Nonprofit' do
      build(:transaction_base, :inherit_from_transaction).save!
      expect(Nonprofit.count).to eq 1
    end

    it 'creates one Supporter' do
      build(:transaction_base, :inherit_from_transaction).save!
      expect(Supporter.count).to eq 1
    end

    it 'creates one OffsitePayment' do 
      build(:transaction_base, :inherit_from_transaction).save!
      expect(OffsitePayment.count).to eq 1
    end

    it 'creates one TransactionAssignment' do 
      build(:transaction_base, :inherit_from_transaction).save!
      expect(TransactionAssignment.count).to eq 1
    end

    it 'creates one ModernDonation' do 
      build(:transaction_base, :inherit_from_transaction).save!
      expect(ModernDonation.count).to eq 1
    end

    it 'creates one Subtransaction' do
      build(:transaction_base, :inherit_from_transaction).save!
      expect(Subtransaction.count).to eq 1
    end

    it 'creates one OfflineTransaction' do
      build(:transaction_base, :inherit_from_transaction).save!
      expect(OfflineTransaction.count).to eq 1
    end

    it 'creates one SubtransactionPayment' do
      build(:transaction_base, :inherit_from_transaction).save!
      expect(SubtransactionPayment.count).to eq 1
    end

    it 'creates one OfflineTransactionCharge' do
      build(:transaction_base, :inherit_from_transaction).save!
      expect(OfflineTransactionCharge.count).to eq 1
    end
    # describe :with_payments do
    #   create(:transaction_base, :with_payments, payment_descs: [
    #     {:offline_transaction_base, :offline_transaction_charge, }
    #   ])
    # end
  end
end