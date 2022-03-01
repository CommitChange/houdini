# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require "rails_helper"

RSpec.describe DisputeMailer, :type => :mailer do
  before(:each) do
    StripeMock.start
  end
  

  describe "created" do
    include_context :dispute_created_context do
      let(:obj) { StripeDispute.create(object:json) }
    end
    let(:mail) { DisputeMailer.created(dispute) }

    it "renders the headers" do
      expect(mail.subject).to eq("New dispute dp_05RsQX2eZvKYlo2C0FRTGSSA for spec_nonprofit_full, evidence due on 2020-08-19 23:59:59 UTC")
      expect(mail.to).to eq(["support@commitchange.com"])
      expect(mail.from).to eq(["support@commitchange.com"])
    end
  end

  describe "funds_withdrawn" do
    include_context :dispute_funds_withdrawn_context
    let(:obj) { StripeDispute.create(object:json) }
    let(:mail) { DisputeMailer.funds_withdrawn(dispute) }

    it "renders the headers" do
      expect(mail.subject).to eq("-$815 withdrawn for dispute dp_05RsQX2eZvKYlo2C0FRTGSSA for spec_nonprofit_full, evidence due on 2020-08-19 23:59:59 UTC")
      expect(mail.to).to eq(["support@commitchange.com"])
      expect(mail.from).to eq(["support@commitchange.com"])
    end
  end

  describe "funds_reinstated" do
    include_context :dispute_funds_reinstated_context
    let(:obj) { StripeDispute.create(object:json) }
    let(:mail) { DisputeMailer.funds_reinstated(dispute) }

    it "renders the headers" do
      expect(mail.subject).to eq("$240 reinstated for dispute dp_15RsQX2eZvKYlo2C0ERTYUIA for spec_nonprofit_full")
      expect(mail.to).to eq(["support@commitchange.com"])
      expect(mail.from).to eq(["support@commitchange.com"])
    end
  end

  describe "won" do
    include_context :dispute_won_context
  
    let(:obj) { StripeDispute.create(object:json) }
    let(:mail) { DisputeMailer.won(dispute) }

    it "renders the headers" do
      expect(mail.subject).to eq("WON dispute dp_15RsQX2eZvKYlo2C0ERTYUIA for spec_nonprofit_full")
      expect(mail.to).to eq(["support@commitchange.com"])
      expect(mail.from).to eq(["support@commitchange.com"])
    end
  end

  describe "lost" do
    include_context :dispute_lost_context
    let(:obj) { StripeDispute.create(object:json) }
    let(:dispute) { obj.dispute }
    let(:mail) { DisputeMailer.lost(dispute) }

    it "renders the headers" do
      expect(mail.subject).to eq("LOST dispute dp_05RsQX2eZvKYlo2C0FRTGSSA for spec_nonprofit_full")
      expect(mail.to).to eq(["support@commitchange.com"])
      expect(mail.from).to eq(["support@commitchange.com"])
    end
  end

  describe "update" do
    before(:each) do
      StripeMock.start
    end
    let(:nonprofit) { transaction.nonprofit}
    let(:json) do
      event = StripeMock.mock_webhook_event('charge.dispute.updated')
      event['data']['object']
    end
    let(:supporter) { transaction.supporter}
    let!(:transaction) {  create(:transaction_for_stripe_dispute_of_80000)}
  
    let(:obj) { StripeDispute.create(object:json) }
    let(:dispute) { obj.dispute }
    let(:mail) { DisputeMailer.updated(dispute) }

    it "renders the headers" do
      expect(mail.subject).to eq("Updated dispute dp_15RsQX2eZvKYlo2C0ERTYUIA for Ending Poverty in the Fox Valley Inc., evidence due on 2019-09-16 00:59:59 UTC")
      expect(mail.to).to eq(["support@commitchange.com"])
      expect(mail.from).to eq(["support@commitchange.com"])
    end
  end

end
