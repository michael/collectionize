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


# fetch minimal techno artists from freebase
get '/github_ecosystems' do
  # TODO: translate ;-)
  JSON.pretty_generate({})
end