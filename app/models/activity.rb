# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class Activity < ActiveRecord::Base
  belongs_to :attachment, :polymorphic => true
end

