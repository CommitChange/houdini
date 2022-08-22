# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module ProfilesHelper

  def get_shortened_name name
    if name
      name.length > 18 ? name[0..18] + '...' : name
    else
      'Your Account'
    end
  end

end
