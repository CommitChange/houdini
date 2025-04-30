# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later

# represents an operation using Mailchimp's batch subscribe/unsubscribe
# See more at: https://mailchimp.com/developer/marketing/api/list-members/
class MailchimpBatchOperation::AddOrUpdate < MailchimpBatchOperation

  def initialize(attributes={})
    super(attributes.merge(method: 'PUT'))
  end

end