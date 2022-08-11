# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class Tracking < ActiveRecord::Base
  attr_accessible :utm_campaign, :utm_content, :utm_medium, :utm_source

  belongs_to :donation
end
