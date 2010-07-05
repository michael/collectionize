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
  :"/location/country/iso_alpha_3" => nil,
  :type => "/location/country",
  :limit => 10
}]


COUNTRY_PROPERTIES = {
  "name" => {:name => "Country Name", :type => "string", :property_key => "name", :value_key => "name", :unique => true},
  "official_language" => {:name => "Official language", :type => "string", :property_key => "official_language", :value_key => "name", :unique => false},
  "form_of_government" => {:name => "Form of governmennt", :type => "string", :property_key => "form_of_government", :value_key => "name", :unique => false},
  "currency_used" => {:name => "Currency used", :type => "string", :property_key => "currency_used", :value_key => "name", :unique => true},
  "population" => {:name => "Population", :type => "number", :property_key => "/location/statistical_region/population", :value_key => "number", :unique => true},
  "gdp_nominal" => {:name => "GDP nominal", :type => "number", :property_key => "/location/statistical_region/gdp_nominal", :value_key => "amount", :unique => true},
  "area" => {:name => "Area", :type => "number", :property_key => "/location/location/area", :unique => true},
  "date_founded" => {:name => "Date founded", :property_key => "/location/dated_location/date_founded", :type => "date", :unqiue => true}
}


WORLD_BANK_PROPERTIES = {
  "population_0014" => {:name => "Population ages 0-14 (% of total)", :indicator => "SP.POP.0014.TO.ZS" },
  "population_1564" => {:name => "Population ages 15-65 (% of total)", :indicator => "SP.POP.1564.TO.ZS" },
  "population_65up" => {:name => "Population ages 65 and above (% of total)", :indicator => "SP.POP.65UP.TO.ZS" },
  
  "life_expectancy_female" => {:name => "Life expectancy at birth (female)", :indicator => "SP.DYN.LE00.FE.IN" },
  "life_expectancy_male" => {:name => "Life expectancy at birth (male)", :indicator => "SP.DYN.LE00.MA.IN" }
}

module Helpers
  def is_numeric?(i)
    i = i.to_s
    i.to_i.to_s == i || i.to_f.to_s == i
  end
end


class Country
  attr_accessor :fb_json, :wb_json
  
  def initialize(country)
    @fb_json = country
    
    fetch_world_bank_indicators
  end
  
  def fetch_world_bank_indicators
    @wb_json = {}
    puts "[2] fetching world bank indicators for #{@fb_json["id"]}"
    WORLD_BANK_PROPERTIES.each do |key, p|
      @wb_json[key] = JSON.parse(Typhoeus::Request.get("http://open.worldbank.org/countries/#{@fb_json["/location/country/iso_alpha_3"]}/indicators[#{p[:indicator]}]?date=2008:2008&format=json").body)
    end
  end
  
  def to_hash
    item = {}
    item[:id] = @fb_json["id"]
    COUNTRY_PROPERTIES.each do |pkey, pdef|
      prop = pdef[:property_key] # freebase property key
      if @fb_json[prop].kind_of?(Array)
        # multi valued
        if pdef[:unique] # just pick the first if property is unique
          item[pkey] = @fb_json[prop][0][pdef[:value_key]]
        else
          item[pkey] = []
          @fb_json[prop].each do |val|
            item[pkey] << val[pdef[:value_key]]
          end
        end
      elsif @fb_json[prop] != nil
        # single value
        item[pkey] = @fb_json[prop]
      end
    end
    item
  end
  
  def self.fetch_countries
    result = {:items => {}, :properties => {} }
    countries = Ken.session.mqlread(COUNTRIES_QUERY) #, :cursor => true)

    puts "[1] retrieved #{countries.length.to_s} countries."
    
    country_objects = []
    countries.each do |country|
      country_objects << Country.new(country)
    end
    
    # properties
    COUNTRY_PROPERTIES.each do |pkey, pdef|
      result[:properties][pkey] = pdef
    end
    
    WORLD_BANK_PROPERTIES.each do |pkey, p|
      result[:properties][pkey] = {
        :name => p[:name],
        :type => "number",
        :unique => true
      }
    end
    
    # items
    country_objects.each do |c|
      item = c.to_hash
      # add world bank attributes
      WORLD_BANK_PROPERTIES.each do |pkey, p|
        begin
          val = c.wb_json[pkey][1][0]["value"]
          
          # if (Helpers.is_numeric?(val))
          #   item[pkey] = val
          #   console.log("HOORAAYYYYYYYYYY")
          # else
          #   item[pkey] = nil
          # end
          
          item[pkey] = val.to_f
        rescue
          item[pkey] = nil
        end
      end
      
      result[:items][item[:id]] = item
      item.delete(:id) # remove id property which was just for memoization
    end
    
    f = File.open("cache/countries.json",  "w") do |f|
      f.write(JSON.pretty_generate(result))
    end
    
    IO.read("cache/countries.json")
  end
end