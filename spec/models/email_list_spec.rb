# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
require 'rails_helper'

RSpec.describe EmailList, :type => :model do
  it { is_expected.to belong_to(:nonprofit) }
  it { is_expected.to belong_to(:tag_master) }
  
  describe '#request_populate_list' do
    it 'queues a PopulateListJob' do
      ActiveJob::Base.queue_adapter = :test
      nonprofit = build(:nonprofit_base)
      email_list = create(:email_list_base, nonprofit:nonprofit, tag_master:build(:tag_master_base, nonprofit:nonprofit))
      expect{email_list.request_populate_list}.to have_enqueued_job(PopulateListJob).with(email_list)
    end
  end

  describe '#deleted?' do
     it 'is false if tag_master is marked as not deleted' do
      nonprofit = build(:nonprofit_base)
      email_list = create(:email_list_base, nonprofit:nonprofit, tag_master:build(:tag_master_base, nonprofit:nonprofit))
      expect(email_list).to_not be_deleted
     end

     it 'is true if tag_master is marked as deleted' do
      nonprofit = build(:nonprofit_base)
      email_list = create(:email_list_base, nonprofit:nonprofit, tag_master:build(:tag_master_base, nonprofit:nonprofit, deleted:true))
      expect(email_list).to be_deleted
     end
  end

  describe '#list_url' do
    it 'is correctly generated' do
      email_list = build_stubbed(:email_list_base)
      expect(email_list.list_url).to eq "lists/"+ email_list.mailchimp_list_id
    end
  end

  describe '#list_members_url' do
    it 'is correctly generated' do
      email_list = build_stubbed(:email_list_base)
      expect(email_list.list_members_url).to eq "lists/"+ email_list.mailchimp_list_id + "/members"
    end
  end

  

  describe "#populate_list" do
    #from insert_email_lists_spec.rb
    let(:np) { create(:nonprofit_base)}
    let(:tag_master) {force_create(:tag_master, nonprofit: np)}
    let(:smaller_tag_master) {create(:tag_master_base, nonprofit: np)}
    let(:smaller_email_list) { create(:email_list_base, nonprofit: np, tag_master: smaller_tag_master)}
    let(:email_list) {force_create(:email_list, mailchimp_list_id: 'list_id', tag_master: tag_master, nonprofit:np, list_name: "temp")}
    let(:supporter_on_both) { force_create(:supporter, nonprofit:np, email: 'on_BOTH@email.com', name: nil)}
    let(:supporter_on_local) { force_create(:supporter, nonprofit:np, email: 'on_local@email.com', name: 'Penelope Rebecca Schultz')}
    let(:supporter_on_smaller_list ) { force_create(:supporter, nonprofit:np, email: 'smaller_list@email.com', name: 'Cacau Lima-Borges')}
    let(:tag_join) {force_create(:tag_join, tag_master: tag_master, supporter: supporter_on_both)}
    let(:tag_join2) {force_create(:tag_join, tag_master: tag_master, supporter: supporter_on_local)}

    def setup
      ActiveJob::Base.queue_adapter = :test
      smaller_email_list
      email_list
      supporter_on_both
      supporter_on_local
      tag_join
      tag_join2
    end

    it 'populates with all of the supporters on list one' do
      setup
      expect(Mailchimp).to receive(:perform_batch_operations).with(any_args)
      email_list.populate_list
    end



    it 'does nothing if #deleted?' do
      setup
      email_list.tag_master.update(deleted:true)
      expect(Mailchimp).to_not receive(:perform_batch_operations)
      email_list.populate_list
    end
  end
end
