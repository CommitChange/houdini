# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
object @payment => :data

attributes :gross_amount, :towards, :net_amount, :fee_total, :id, :date, :refund_total, :kind

node(:consider_donation_anonymous) do |p|
    d_anonymous = p.donation.nil? ? false : p.donation.anonymous

    !!d_anonymous || !!p.supporter.anonymous
end

node(:fee_covered) do |p|
  !!p.misc_payment_info&.fee_covered
end


child :charge do
  attributes :created_at, :id
  node(:status) {|c| c.status.humanize}
end

child :donation, object_root: false do
    attributes :designation, :dedication, :origin_url, :id, :comment


  child :campaign, object_root: false do
  	attributes :name, :url, :id
  end

  node(:campaign_gift){|d| {name: d.campaign_gifts.any? ? d.campaign_gifts.last.campaign_gift_option.name : nil}}

  child :event, object_root: false do
    attributes :name, :url, :id
  end

	child :recurring_donation, object_root: false do
		attributes :interval, :time_unit, :created_at
	end
end

child :disputes, object_root: false do
  attributes :id
  node(:status) {|d| d.status.humanize}
  node(:reason) {|d| d.reason.humanize}
  child :dispute_transactions, object_root: false do 
    child :payment do 
      attributes :id, :net_amount, :gross_amount, :fee_total
      node(:href) {|p| nonprofits_payments_url(p.nonprofit,  pid: p.id)}  
    end
  end
end

child :dispute_transaction do 
  attributes :id, :date
  child :dispute do 
    attributes :id
    node(:status) {|d| d.status.humanize}
    node(:reason) {|d| d.reason.humanize}
    child :original_payment, object_root: false do
      attributes :id, :net_amount, :gross_amount, :fee_total
      node(:href) {|p| nonprofits_payments_url(p.nonprofit,  pid: p.id)}  
    end
    
  end
end

child :refund do
	attributes :reason, :comment, :disbursed
end

child :offsite_payment do
	attributes :check_number, :kind
end


node(:ticket) do |payment|
  event = payment&.tickets&.last&.event
  h = {
    event: {name: event&.name, url: event&.url, id: event&.id},
    levels: payment.tickets.map{|t| "#{GetData.chain(t.ticket_level, :name)} (#{t.quantity}x)"}.join(", "),
    discount: payment.tickets.map{|t| t.event_discount ? "#{t.event_discount.name} (#{t.event_discount.percent}%)" : nil}.compact.join(", ")
  }
  event ? h : nil
end

child :tickets, object_root: false do
	attributes :id

	child :ticket_level do
		attributes :name
	end
end

child :supporter do
	attributes :name, :email, :city, :state_code, :address, :zip_code, :phone, :id, :country
  node(:url) {|s| nonprofits_supporters_url(s.nonprofit, {sid: s.id})}
end

child :nonprofit do
    attributes :id
end
