require 'rubygems'
require 'ken'
require 'sinatra'
require 'json'

COUNTRIES_QUERY = [{
  :id => nil,
  :name => nil,
  :languages_spoken => [{:id => nil, :name => nil}],
  :form_of_government => [{:id => nil, :name => nil}],
  :currency_used => [{:id => nil, :name => nil}],
  :"/location/statistical_region/gdp_nominal" => [{:amount => nil, :valid_date => nil, :currency => nil}],
  :"/location/statistical_region/population" => [{:number => nil, :year => nil, :limit => 1, :sort => "-year"}],
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
  # content_type :json  
  result = {:items => [], :facet_categories => {} }
  countries = Ken.session.mqlread(COUNTRIES_QUERY, :cursor => true)

  countries.each do |country|
    item = {
      :name => country["name"],
      :facets => []
    }
    
    # language facet
    facet = {:values => []}
    country["languages_spoken"].each do |l|
      facet[:values] << {:id => l["id"], :name => l["name"]}
    end
    item[:facets] << facet    
    result[:items] << item
    
  end
  result.to_json
end

# fetch countries from freebase
get '/minimal_techno_artists' do
  artists = Ken.session.mqlread(ARTISTS_QUERY)
  # TODO: translate ;-)
  artists.to_json
end