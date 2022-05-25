## ONLY USED FOR TESTING
class SimpleObject < ActiveRecord::Base
  include Model::Houidable
  setup_houid :smplobj, :houid
  belongs_to :parent, class_name: "SimpleObject"
  belongs_to :nonprofit

  has_many :friends, class_name: "SimpleObject", foreign_key: 'friend_id'

  def publish_created
    ObjectEvent.create(event_entity:self, event_type: 'simple_object.created')
  end

  def publish_updated
    ObjectEvent.create(event_entity:self, event_type: 'simple_object.updated')
  end
end
