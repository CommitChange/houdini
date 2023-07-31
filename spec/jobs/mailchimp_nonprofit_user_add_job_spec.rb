# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

RSpec.describe MailchimpNonprofitUserAddJob, type: :job do
  let(:user) {create(:user)}
  let(:nonprofit) {create(:nonprofit_base)}
  let(:drip_email_list) {create(:drip_email_list_base)}

  it 'runs job' do 
    expect(Mailchimp).to receive(:signup_nonprofit_user).with(drip_email_list, user, nonprofit)
    MailchimpNonprofitUserAddJob.perform_now(drip_email_list, user, nonprofit)
  end 
  
end
