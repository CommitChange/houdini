# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class FullContactPhoto < ApplicationRecord

  belongs_to :full_contact_info

  validates :full_contact_info, presence: true
end
