# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
# Preview all emails at http://localhost:5000/rails/mailers/tax_mailer
class TaxMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods
  # Preview this email at http://localhost:5000/rails/mailers/tax_mailer/annual_receipt
  def annual_receipt
    tax_id = "12-3456789"
    supporter = create(:supporter_generator, nonprofit: build(:nonprofit_base, ein: tax_id))

    tax_year = 2023
    payments = build_list(:donation_payment_generator, Random.rand(5) + 1,
        supporter: supporter,
        nonprofit: supporter.nonprofit
    )

    nonprofit_text = "<p>#{Faker::Lorem.paragraph(sentence_count: 5)}</p>" + "<p>#{Faker::Lorem.paragraph(sentence_count:3)}</p>"
    TaxMailer.annual_receipt(year: tax_year, supporter: supporter, nonprofit_text: nonprofit_text, donation_payments: payments)
  end

  # Preview this email at http://localhost:5000/rails/mailers/tax_mailer/annual_receipt_with_refunds
  def annual_receipt_with_refunds
    tax_id = "12-3456789"
    supporter = create(:supporter_generator, nonprofit: build(:nonprofit_base, ein: tax_id))

    tax_year = 2023
    payments = create_list(:donation_payment_generator, Random.rand(5) + 1,
        supporter: supporter,
        nonprofit: supporter.nonprofit
    )

    refund_payments = create_list(:refund_payment_generator, Random.rand(5) + 1,
      supporter: supporter,
      nonprofit: supporter.nonprofit
    ) 

    nonprofit_text = "<p>#{Faker::Lorem.paragraph(sentence_count: 5)}</p>" + "<p>#{Faker::Lorem.paragraph(sentence_count:3)}</p>"
    TaxMailer.annual_receipt(year: tax_year, supporter: supporter, nonprofit_text: nonprofit_text, donation_payments: payments, refund_payments: refund_payments)
  end

   # Preview this email at http://localhost:5000/rails/mailers/tax_mailer/annual_receipt_with_disputes
   def annual_receipt_with_disputes
    tax_id = "12-3456789"
    supporter = create(:supporter_generator, nonprofit: build(:nonprofit_base, ein: tax_id))

    tax_year = 2023
    payments = create_list(:donation_payment_generator, Random.rand(5) + 1,
        supporter: supporter,
        nonprofit: supporter.nonprofit
    )

    dispute_payments = create_list(:dispute_payment_generator, Random.rand(5) + 1,
      supporter: supporter,
      nonprofit: supporter.nonprofit
    )

    dispute_reversal_payments = create_list(:dispute_reversal_payment_generator, Random.rand(5) + 0,
      supporter: supporter,
      nonprofit: supporter.nonprofit
    ) 

    nonprofit_text = "<p>#{Faker::Lorem.paragraph(sentence_count: 5)}</p>" + "<p>#{Faker::Lorem.paragraph(sentence_count:3)}</p>"
    TaxMailer.annual_receipt(year: tax_year, supporter: supporter, nonprofit_text: nonprofit_text, donation_payments: payments, dispute_payments: dispute_payments, dispute_reversal_payments: dispute_reversal_payments)
  end


end
