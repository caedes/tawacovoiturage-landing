require 'rubygems'
require 'sinatra/base'
require 'uri'
require 'mongo'
require 'haml'
require 'json'

class LandingPad < Sinatra::Base
  set :static, true
  set :public_folder, 'public'

  configure do
    raise 'Admin credentials not yet set.' unless ENV['ADMIN_CREDENTIALS']

    # Admin settings - used to access contacts
    $admin_acct_name = ENV['ADMIN_CREDENTIALS'].split(':').first
    $admin_acct_passwd = ENV['ADMIN_CREDENTIALS'].split(':').last

    # Database settings - do NOT change these
    if ENV['MONGOHQ_URL']
      uri = URI.parse ENV['MONGOHQ_URL']
      conn = Mongo::Connection.from_uri ENV['MONGOHQ_URL']
      db = conn.db uri.path.gsub(/^\//, '')
    else
      conn = Mongo::Connection.new 'localhost', 27017, safe: true
      db = conn.db 'tawacovoiturage_development'
    end

    $collection = db.collection 'contacts'
  end

  helpers do
    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw :halt, [401, "Not authorized\n"]
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new request.env
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [$admin_acct_name, $admin_acct_passwd]
    end
  end

  get '/' do
    haml :index
  end

  get '/contacts' do
    protected!
    @contacts = $collection.find
    haml :contacts
  end

  get '/contacts.json' do
    protected!
    content_type :json
    @contacts = $collection.find
    @results = @contacts.to_a
    JSON.dump @results
  end

  post '/subscribe' do
    content_type :json
    contact = params[:contact]
    contact_type = contact.start_with?('@') ||
                  !contact.include?('@') ? 'Twitter' : 'Email'

    doc = {
      name: contact,
      type: contact_type,
      referer: request.referer,
      created_at: Time.now
    }

    $collection.insert(doc)
      {success: true, type: contact_type}.to_json
    end
end
