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

COUNTRY_PROPERTIES = {
  "languages_spoken" => {:name => "Languages spoken", :value_key => "name"},
  "form_of_government" => {:name => "Form of governmennt", :value_key => "name"},
  "currency_used" => {:name => "Currency used", :value_key => "name"}
}

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
  "this service provides some collections (/countries, /minimal_artists)"
end

# fetch countries from freebase
get '/countries' do
  # content_type :json  
  result = {:items => [], :properties => {} }
  countries = Ken.session.mqlread(COUNTRIES_QUERY, :cursor => true)
  
  # properties
  COUNTRY_PROPERTIES.each do |pkey, pdef|
    result[:properties][pkey] = pdef
  end
  
  # items
  countries.each do |country|
    item = {
      :name => country["name"],
      :attributes => []
    }
    
    COUNTRY_PROPERTIES.each do |pkey, pdef|
      attribute = {:values => []}
      country[pkey].each do |val|
        attribute[:values] << {:id => val["id"], :value => val[pdef[:value_key]]}
      end
      
      item[:attributes] << attribute
    end
    
    result[:items] << item
    
  end
  result.inspect
end

# fetch minimal techno artists from freebase
get '/minimal_techno_artists' do
  artists = Ken.session.mqlread(ARTISTS_QUERY)
  # TODO: translate ;-)
  artists.to_json
end