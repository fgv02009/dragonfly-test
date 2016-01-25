require 'dragonfly'
require 'dragonfly/s3_data_store'
# Configure
Dragonfly.app.configure do
  plugin :imagemagick

  secret "a2faf48576dba16a2dfcacc34c11f28c3a2cb1c3160864f5b27a774d9d936a8a"

  url_format "/media/:job/:name"

  if Rails.env.development? || Rails.env.test?
    datastore :file,
              root_path: Rails.root.join('public/system/dragonfly', Rails.env),
              server_root: Rails.root.join('public')
  else
    datastore :s3,
              bucket_name: ENV['BUCKET_NAME'],
              access_key_id: ENV['ACCESS_KEY_ID'],
              secret_access_key: ENV['SECRET_ACCESS_KEY'],
              url_scheme: 'https'
  end
  # Override the .url method...
  define_url do |app, job, opts|
    thumb = Thumb.find_by_job(job.signature)
    # If (fetch 'some_uid' then resize to '180x180') has been stored already, give the datastore's remote url ...
    if thumb
      app.datastore.url_for(thumb.uid, :scheme => 'http')
      # "https://s3.amazonaws.com/#{ENV['BUCKET_NAME']}.mydomain.com/myObjectKey."
      # ...otherwise give the local Dragonfly server url
    else
      app.server.url_for(job)
    end
  end

  # Before serving from the local Dragonfly server...
  before_serve do |job, env|
    # ...store the thumbnail in the datastore...
    uid = job.store

    # ...keep track of its uid so next time we can serve directly from the datastore
    Thumb.create!(
        :uid => uid,
        :job => job.signature   # 'BAhbBls...' - holds all the job info
    )                           # e.g. fetch 'some_uid' then resize to '180x180'
  end
end


# Logger
Dragonfly.logger = Rails.logger

# Mount as middleware
Rails.application.middleware.use Dragonfly::Middleware

# Add model functionality
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend Dragonfly::Model
  ActiveRecord::Base.extend Dragonfly::Model::Validations
end
