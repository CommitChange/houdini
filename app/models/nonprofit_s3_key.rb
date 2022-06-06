# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later

class NonprofitS3Key < ActiveRecord::Base
  belongs_to :nonprofit, required: true

  validates_presence_of :access_key_id, :secret_access_key, :bucket_name

  
end
