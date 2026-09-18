# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class FullContactInfo < ApplicationRecord

  has_many :full_contact_photos, dependent: :destroy
  has_many :full_contact_social_profiles, dependent: :destroy
  has_many :full_contact_orgs, dependent: :destroy
  has_many :full_contact_topics, dependent: :destroy
  belongs_to :supporter
end
