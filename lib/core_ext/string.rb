# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later

class String
  def is_int?
    !!(self =~ /\A\d+\z/)
  end
end
