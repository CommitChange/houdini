# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Full license explanation at https://github.com/houdiniproject/houdini/blob/main/LICENSE

class JsonExpectations::ObjectEventExpectation
  include RSpec::Matchers
  include ActiveModel::AttributeAssignment
  attr_accessor :type, :data
  attr_writer :created, :houid, 
  
  def initialize(new_attributes)
    assign_attributes(new_attributes)
  end

  def houid
    @houid || match_houid(:evt)
  end

  def created
    @created || Time.current
  end

  def output
    output = {
      'id' => houid,
      'created' => created.to_i,
      'object' => 'object_event',
      'type' => type,
      'data' => {
        'object' => data
      }
    }
  end
end