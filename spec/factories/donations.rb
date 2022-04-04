# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
FactoryBot.define do
  factory :donation do
  end

  factory :donation_base, class: 'Donation' do
    nonprofit {supporter.nonprofit}
    amount {333}
    # created_at {Time.current} 
    # supporter { association :supporter_base}
    # payments {[build(:payment_base, supporter: supporter, gross_amount: gross_amount, fee_total: 0, net_amount: gross_amount, date: created_at)]}

    # trait :with_charge do
    #   transient do
    #     stripe_charge_id { "ch_1Y7zzfBCJIIhvMWmSiNWrPAC"}
    #   end
    #   payments{[
    #     build(:payment_base, supporter: supporter, gross_amount: amount, fee_total: 0, net_amount: amount, date: created_at,
    #     charge: build(:charge_base, amount: amount, stripe_charge_id: stripe_charge_id, created_at: date, supporter:supporter,  nonprofit: nonprofit)
    #     )]}
    # end

  
    # supporter { association :supporter_base}
    # payments {[build(:payment_base, supporter: supporter)]}
  end
  

  factory :fv_poverty_donation, class: 'Donation' do
    nonprofit {association  :fv_poverty}

    supporter { build(:supporter_with_fv_poverty, nonprofit: nonprofit)}
    amount  {333}
    factory :donation_with_dedication_designation do 
      dedication { {
        contact: {
          email: 'email@ema.com'
        },
        name: 'our loved one',
        note: "we miss them dearly",
        type: 'memory'
      } }
      designation { 'designated for soup kitchen'}

      nonprofit {association  :fv_poverty}

      supporter { association  :supporter}
      amount  {500}
    end
  end  
end
