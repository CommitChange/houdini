# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
module MockHelpers
  def self.payment_export_headers()
    ["Date",'Gross Amount',	'Fee Total',	'Net Amount','Type',	'Last Name',	'First Name', 'Just First Name', 'Full Name', 'Organization',	'Email',	'Phone',	'Address',	'City',	'State',	'Postal Code',	'Country', 'Supporter Id',	 'Designation', "Dedication Type",
        "Dedicated To: Name",
        "Dedicated To: Supporter Id",
        "Dedicated To: Email",
        "Dedicated To: Phone",
        "Dedicated To: Address",
        "Dedicated To: Note", 'Anonymous?', 'Comment','Campaign',	'Campaign Id', 'Campaign Creator Email', 'Campaign Gift Level',	'Event Name',	'Payment',	'Check Number', 'Donation Note', 'Recurring Donation Started At', "Fee Covered By Supporter"]
  end

  def self.recurring_donation_export_headers()
    ["Created At",
      "Amount",
      "Interval",
      "Total Contributed",
      "Campaign Name",
      "Supporter Name",
      "Supporter Email",
      "Phone",
      "Address",
      "City",
      "State",
      "Zip Code",
      "Card Name",
      "Recurring Donation Id",
      "Donation Id", 
      "Designation",
      "Fee Covered By Supporter",
      "Status", 
      "Cancelled At", 
      "Donation Management Url",
      "Paydate", 
      "Last Charge Succeeded"]
  end

  def self.recurring_donation_export_headers_with_last_failed_charge
    self.recurring_donation_export_headers.push("Last Failed Charge")
  end

  def self.generate_expected_rd_management_url(root_url, rd)
    "#{root_url}/recurring_donations/#{rd.id}/edit?t=#{rd.edit_token}"
  end
end