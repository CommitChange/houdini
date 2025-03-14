# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module Path
  extend ActiveSupport::Concern

  class_methods do
    ModernParams = Struct.new(:to_param)
  end

  included do
    # When you use a routing helper like `api_new_nonprofit_supporter``, you need to provide objects which have a `#to_param`
    # method. By default that's set to the value of `#id`. In our case, for the api objects, we want the id to instead be
    # the value of `#houid`. We can't override `to_param` though because we may use route helpers which expect `#to_param` to
    # return the value of `#id`. This is the hacky workaround.
    def to_modern_param
      ModernParams.new(houid)
    end
  end
end
