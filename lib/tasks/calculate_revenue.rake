# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
desc "Fetches charges given a period and calculates revenue from Stripe data"

namespace :calculate_revenue do
  task :to_database, [:stripe_api_key, :start_date, :end_date] => :environment do |t, args|
    Stripe.api_key = args[:stripe_api_key].gsub('"', '')
    start_date = (args[:start_date].gsub('"', '')).to_str
    end_date = (args[:end_date].gsub('"', '')).to_str

    charges = Charge.where(
      "created_at :: date >= '#{start_date}' \
      AND created_at :: date < '#{end_date}' \
      AND stripe_charge_id IS NOT NULL\
      AND revenue IS NULL"
    )

    charges.each do |c|
      begin
        stripe_charge = Stripe::Charge.retrieve({id: c.stripe_charge_id, expand: ['balance_transaction']})
        c.revenue = calculate_revenue(stripe_charge, c.created_at)
        c.save!
      rescue => exception
        puts(exception)
      end
    end
  end

  task :export_uncalculated_revenues, [:start_date, :end_date] => :environment do |t, args|
    start_date = (args[:start_date].gsub('"', '')).to_str
    end_date = (args[:end_date].gsub('"', '')).to_str

    charges = Charge.where(
      "created_at :: date >= '#{start_date}' \
      AND created_at :: date < '#{end_date}' \
      AND stripe_charge_id IS NOT NULL\
      AND revenue IS NULL"
    )

    csv_string = Format::Csv.from_data(
      charges.map do |c|
        {
          created_at: c.created_at,
          stripe_charge_id: c.stripe_charge_id,
          fee: c.fee,
          amount: c.amount,
          nonprofit_id: c.nonprofit_id
        }
      end
    )
    File.write("uncalculated_revenues_#{start_date}-#{end_date}.csv", csv_string)
  end

  task :export_to_csv, [:start_date, :end_date] => :environment do |t, args|
    start_date = (args[:start_date].gsub('"', '')).to_str
    end_date = (args[:end_date].gsub('"', '')).to_str

    charges = Charge.where(
      "created_at :: date >= '#{start_date}' \
      AND created_at :: date < '#{end_date}' \
      AND stripe_charge_id IS NOT NULL\
      AND revenue IS NOT NULL"
    )

    csv_string = Format::Csv.from_data(
      charges.map do |c|
        {
          created_at: c.created_at.strftime('%Y-%m'),
          revenue: c.revenue,
          nonprofit_id: c.nonprofit_id
        }
      end
    )
    File.write("revenue_#{start_date}-#{end_date}.csv", csv_string)
  end

  def calculate_revenue(charge, date)
    return (charge.application_fee_amount - (charge.balance_transaction.fee + (charge.amount * BigDecimal.new('0.0015')))).to_i if date >= Time.new(2020, 12, 1)
    (charge.application_fee_amount - charge.balance_transaction.fee).to_i
  end
end
