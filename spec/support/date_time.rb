# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class DateTime
  def nsec
    (sec_fraction * 1_000_000_000).to_i
  end
end