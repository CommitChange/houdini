# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module DeviseHelper
  def devise_error_messages!
    if resource && !resource.errors.empty?
      resource.errors.first.first.to_s + ' ' + 
        resource.errors.first.second
    end
  end
end
