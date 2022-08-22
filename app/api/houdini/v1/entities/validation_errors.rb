# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class Houdini::V1::Entities::ValidationErrors < Grape::Entity
  expose :errors, documentation: {type: ValidationError, desc: 'errors', is_array:true}
end