# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class FullContactTopic < ActiveRecord::Base

	attr_accessible \
    :provider,
    :value,
    :full_contact_info_id, :full_contact_info

  belongs_to :full_contact_info

end
