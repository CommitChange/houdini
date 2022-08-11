# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
class SupporterAddress < ActiveRecord::Base
  belongs_to :supporter, required:true, inverse_of: :addresses

  def primary?
    supporter&.primary_address == self
  end
end
