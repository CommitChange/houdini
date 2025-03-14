# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module EmailLists
  extend ActiveSupport::Concern
  include Supporter::Tags # not needed but helpful for tracking dependencies
  included do
    has_many :email_lists, through: :tag_masters
    has_many :active_email_lists, through: :undeleted_tag_masters, source: :email_list do
      def update_member_on_all_lists
        proxy_association.reload.target.each do |list| # We're reloading the association and running .each on target
          #to make sure we get any newly saved email lists. I think this should be simpler but I'm not sure how to do it.
          MailchimpSignupJob.perform_later(proxy_association.owner, list)
        end
      end
    end

    after_save :try_update_member_on_all_lists
  end

  def must_update_email_lists?
    changes.has_key?("name") || changes.has_key?("email")
  end

  def publish_created
    object_events.create(event_type: 'supporter.created')
  end

  private

  def try_update_member_on_all_lists
    update_member_on_all_lists if must_update_email_lists?
  end

  def update_member_on_all_lists
    active_email_lists.update_member_on_all_lists
  end
end
