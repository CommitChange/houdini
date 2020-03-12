# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper.rb'

describe JobTypes::NonprofitFirstChargeEmail do
  describe '.perform' do
    it 'calls the correct active mailer' do
      expect(fail).to receive(:fail).with(fail).and_wrap_original{|m, *args|  mailer = double('object'); expect(mailer).to receive(:deliver).and_return(nil); mailer}

      job = JobTypes::NonprofitFirstChargeEmail.new(fail)
      job.perform
    end
  end
end