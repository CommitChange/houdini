# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later

# represents an operation using Mailchimp's batch subscribe/unsubscribe
# See more at: https://mailchimp.com/developer/marketing/api/list-members/
class MailchimpBatchOperation
  include ActiveModel::Model
  
  attr_accessor :method, # POST or DELETE
    :list, # the EmailList you're applying this to
    :supporter # the Supporter in question

  def body
    Mailchimp::create_subscribe_body(supporter)
  end

  def path
    list.list_members_path
  end

  def to_h
    {method: method, body: body, path: path}
  end
end