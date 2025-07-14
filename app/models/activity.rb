# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class Activity < ApplicationRecord
  belongs_to :attachment, polymorphic: true, optional: false
  belongs_to :supporter, optional: false
  belongs_to :nonprofit, optional: false
  belongs_to :user, optional: true
end
