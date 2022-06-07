# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later

class NonprofitS3Key < ActiveRecord::Base
  belongs_to :nonprofit, required: true

  validates_presence_of :access_key_id, :secret_access_key, :bucket_name

  def aws_client
    ::Aws::Client.new(credentials:credentials)
  end

  def credentials
    ::Aws::Credentials.new(access_key_id, secret_access_key)
  end

  def s3_resource
    ::Aws::S3::Resources.new(client: aws_client)
  end

  def s3_bucket
    s3_resource.bucket(bucket_name)
  end
end
