# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class EventDiscount < ActiveRecord::Base
  attr_accessible \
    :code,
    :event_id,
    :name,
    :percent

  belongs_to :event
  has_many :tickets

end
