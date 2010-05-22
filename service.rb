require 'rubygems'
require 'ken'
require 'sinatra'
require 'json'

COUNTRIES_QUERY = [{
  :id => nil,
  :name => nil,
  :official_language => [{:id => nil, :name => nil}],
  :form_of_government => [{:id => nil, :name => nil}],
  :currency_used => [{:id => nil, :name => nil}],
  :"/location/statistical_region/gdp_nominal" => [{:amount => nil, :valid_date => nil, :currency => nil, :limit => 1, :sort => "-valid_date"}],
  :"/location/statistical_region/population" => [{:number => nil, :year => nil, :limit => 1, :sort => "-year"}],
  :"/location/dated_location/date_founded" => nil,
  :"/location/location/area" => nil,
  :type => "/location/country"
}]

COUNTRY_PROPERTIES = {
  "name" => {:name => "Country Name", :type => "string", :property_key => "name", :value_key => "name", :unique => true},
  "official_language" => {:name => "Official language", :type => "string", :property_key => "official_language", :value_key => "name", :unique => true},
  "form_of_government" => {:name => "Form of governmennt", :type => "string", :property_key => "form_of_government", :value_key => "name", :unique => false},
  "currency_used" => {:name => "Currency used", :type => "string", :property_key => "currency_used", :value_key => "name", :unique => true},
  "population" => {:name => "Population", :type => "number", :property_key => "/location/statistical_region/population", :value_key => "number", :unique => true},
  "gdp_nominal" => {:name => "GDP nominal", :type => "number", :property_key => "/location/statistical_region/gdp_nominal", :value_key => "amount", :unique => true},
  "area" => {:name => "Area", :type => "number", :property_key => "/location/location/area", :unique => true},
  "date_founded" => {:name => "Date founded", :property_key => "/location/dated_location/date_founded", :type => "date", :unqiue => true}
}

get '/' do
  'This service provides some collections:<br/>
  <ul>
    <li><a href="/countries">Countries</a></li>
    <li><a href="/playlists">Playlists from Last.fm</a></li>
    <li><a href="/github_ecosystems">Github Ecosystems</a> (not ready)</li>
  </ul>'
end

get '/countries' do
  result = {:items => [], :properties => {} }
  countries = Ken.session.mqlread(COUNTRIES_QUERY, :cursor => true)
  
  # properties
  COUNTRY_PROPERTIES.each do |pkey, pdef|
    result[:properties][pkey] = pdef
  end
  
  # items
  countries.each do |country|
    item = {}
    COUNTRY_PROPERTIES.each do |pkey, pdef|
      prop = pdef[:property_key] # freebase property key
      if country[prop].kind_of?(Array)
        # multi valued
        if pdef[:unique] # just pick the first if property is unique
          item[pkey] = country[prop][0][pdef[:value_key]]
        else
          item[pkey] = []
          country[prop].each do |val|
            item[pkey] << val[pdef[:value_key]]
          end
        end
      elsif country[prop] != nil
        # single value
        item[pkey] = country[prop]
      end
      
    end
    result[:items] << item
  end
  
  JSON.pretty_generate(result)
end


class PlayList
  SERVICE_URI = "http://ws.audioscrobbler.com/2.0/"

  PARAMS = {
    :api_key => "b25b959554ed76058ac220b7b2e0a026",
    :format => "json"
  }
  
  def initialize(options)
    @title = options["title"]
    @date = options["date"]
    @artists = options["trackList"]["track"].map { |t| t["creator"]}
    @songs = options["trackList"]["track"].map { |t| "#{t["creator"]} - #{t["title"]}" }
    @song_count = @songs.length
  end
  
  def to_hash
    {
      :name => @title,
      :artists => @artists,
      :songs => @songs,
      :song_count => @song_count
    }
  end
  
  def self.get(playlist_id)
    response = http_request(SERVICE_URI, PARAMS.merge(:method => "playlist.fetch", :playlistURL => "lastfm://playlist/#{playlist_id.to_s}"))
    
    return nil unless JSON.parse(response)["playlist"]
    playlist = JSON.parse(response)["playlist"]
    playlist["trackList"]["track"].kind_of?(Array) ? PlayList.new(playlist) : nil
  end
  
  def self.group_users(group_name)
    response = http_request(SERVICE_URI, PARAMS.merge(:method => "group.getmembers", :group => group_name))
    json = JSON.parse(response)
    users = json["members"]["user"].map {|u| u["name"]}
  end
  
  def self.user_playlists(user_name)
    response = http_request(SERVICE_URI, PARAMS.merge(:method => "user.getplaylists", :user => user_name))
    json = JSON.parse(response)
    
    return [] if !json["playlists"] || !json["playlists"]["playlist"]
    playlists = json["playlists"]["playlist"]
    playlists = [playlists] if playlists.kind_of?(Hash)
    playlists.map { |p| p["id"] }    
  end
  
  # does the dirty work
  def self.http_request(url, parameters = {})
    params = params_to_string(parameters)
    url << '?'+params unless params !~ /\S/
          
    Net::HTTP.get_response(::URI.parse(url)).body
  end
  
  # encode parameters
  def self.params_to_string(parameters)
    parameters.keys.map {|k| "#{URI.encode(k.to_s)}=#{URI.encode(parameters[k].to_s)}" }.join('&')
  end
end


PLAYLIST_PROPERTIES = {
  "name" => {:name => "Playlist Name", :type => "string", :unique => true},
  "artists" => {:name => "Artists", :type => "string", :unique => false},
  "songs" => {:name => "Songs", :type => "string", :unique => false},
  "song_count" => {:name => "Song count", :type => "number", :unique => false}
}

get '/playlists' do
  result = {:items => [], :properties => {} }
  
  # properties
  PLAYLIST_PROPERTIES.each do |pkey, pdef|
    result[:properties][pkey] = pdef
  end
  
  users = PlayList.group_users('austria')
  
  playlists = []
  users.each do |u|
    playlists.concat(PlayList.user_playlists(u))
  end
  
  playlists.each do |p|
    pl = PlayList.get(p)
    # only use playlists with at least two songs
    result[:items] << pl.to_hash if pl
  end

  JSON.pretty_generate(result)
end

# fetch ecosystems from github
get '/github_ecosystems' do
  # TODO: translate ;-)
  JSON.pretty_generate({})
end