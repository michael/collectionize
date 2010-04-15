require 'rubygems'
require 'ken'
require 'sinatra'

COUNTRIES_QUERY = [{
  :id => nil,
  :name => nil,
  :languages_spoken => [{:id => nil, :name => nil}],
  :form_of_government => [{:id => nil, :name => nil}],
  :currency_used => [{:id => nil, :name => nil}],
  :gdp_nominal => nil,
  :"/location/statistical_region/religions" => [{:religion => nil, :percentage => nil}],
  :type => "/location/country"
}]

ARTISTS_QUERY = [{
  :album => [{
    :id => nil,
    :name => nil,
  }],
  :id =>   nil,
  :name => nil,
  :"/music/artist/genre" => [{
    :id => "/en/minimal_techno"
  }],
  :type => "/music/artist"
}]

get '/' do
  "this service provides some collections"
end

# fetch countries from freebase
get '/countries' do
  countries = Ken.session.mqlread(COUNTRIES_QUERY)
  # TODO: translate ;-)
  countries.inspect
end

# fetch countries from freebase
get '/minimal_techno_artists' do
  artists = Ken.session.mqlread(ARTISTS_QUERY)
  # TODO: translate ;-)
  artists.inspect
end