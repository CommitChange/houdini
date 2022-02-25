# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class ObjectEvent < ApplicationRecord
  include Model::CreatedTimeable
  attr_accessor :object_as
  
  setup_houid :evt, :houid

  belongs_to :event_entity, polymorphic: true
  belongs_to :nonprofit

  concerning :Query do

    class_methods do 
      def event_entity(event_entity_houid)
        where(event_entity_houid:event_entity_houid)
      end

      def event_types(types)
        where('event_type IN (?)', types)
      end
    end
  end

  before_validation do
    write_attribute(:object_json, to_object) if event_entity
    write_attribute(:nonprofit_id, event_entity&.nonprofit&.id) if event_entity.respond_to? :nonprofit
    write_attribute(:event_entity_houid, event_entity&.houid)
  end

  def to_object
    ApiNew::ObjectEventsController.render 'api_new/object_events/generate', 
      assigns: {
        object_event:self,
        event_entity: event_entity,
        partial_path: "api_new/#{event_entity.to_partial_path.split('/').delete_at(0)}/object_events/base"
      }
  end
end
