# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class EmailList < ActiveRecord::Base
  belongs_to :nonprofit
  belongs_to :tag_master

  has_many :tag_joins, through: :tag_master

  has_many :supporters, through: :tag_joins

  def list_url
   "lists/#{mailchimp_list_id}"
  end

  def list_members_url
    list_url + "/members"
  end

  def deleted?
    tag_master&.deleted
  end

  def request_populate_list
    PopulateListJob.perform_later(self)
  end

  def create_supporter_batch_contents(supporter)
    {method: 'POST', path: list_members_url, body: Mailchimp::create_subscribe_body(supporter).to_json}
  end

  def populate_list
    unless deleted?
      Mailchimp.perform_batch_operations(nonprofit.id, supporters.all.map do |s|
        create_supporter_batch_contents(s)
      end)
    end
  end
end
