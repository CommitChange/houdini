# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module Tags
  extend ActiveSupport::Concern
  included do
    has_many :tag_joins, dependent: :destroy
    has_many :tag_masters, through: :tag_joins
    has_many :undeleted_tag_masters, -> { not_deleted }, through: :tag_joins, source: 'tag_master'
  end
end
