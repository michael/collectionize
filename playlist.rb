PLAYLIST_PROPERTIES = {
  "name" => {:name => "Playlist Name", :type => "string", :unique => true},
  "artists" => {:name => "Artists", :type => "string", :unique => false},
  "songs" => {:name => "Songs", :type => "string", :unique => false},
  "song_count" => {:name => "Song count", :type => "number", :unique => false}
}

class PlayList
  attr_accessor :song_count
  SERVICE_URI = "http://ws.audioscrobbler.com/2.0/"

  PARAMS = {
    :api_key => "b25b959554ed76058ac220b7b2e0a026",
    :format => "json"
  }
  
  def initialize(options, seed_artists)
    @title = options["title"]
    @date = options["date"]
    
    @artists = []
    @songs = []
    options["trackList"]["track"].each do |t|
      if seed_artists.include?(t["creator"])
        @artists << t["creator"]
        @songs << "#{t["creator"]} - #{t["title"]}"
      end
    end

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
  
  def self.get(playlist_id, seed_artists = [])
    response = http_request(SERVICE_URI, PARAMS.merge(:method => "playlist.fetch", :playlistURL => "lastfm://playlist/#{playlist_id.to_s}"))
    
    return nil unless JSON.parse(response)["playlist"]
    playlist = JSON.parse(response)["playlist"]
    
    if playlist["trackList"]["track"].kind_of?(Array)
      pl = PlayList.new(playlist, seed_artists)
      return pl.song_count == 0 ? nil : pl
    end
    nil
  end
  
  def self.group_users(group_name)
    response = http_request(SERVICE_URI, PARAMS.merge(:method => "group.getmembers", :group => group_name))
    json = JSON.parse(response)
    users = json["members"]["user"].map {|u| u["name"]}
  end
  
  def self.artist_fans(artist_name)
    params = PARAMS.merge(:method => "artist.gettopfans", :artist => artist_name)
    
    response = http_request(SERVICE_URI, params)
    json = JSON.parse(response)
    users = json["topfans"]["user"].map {|u| u["name"]}
  end
  
  def self.user_playlists(user_name)
    response = http_request(SERVICE_URI, PARAMS.merge(:method => "user.getplaylists", :user => user_name))

    begin
      json = JSON.parse(response)
    rescue
      puts response
      return []
    end
    
    return [] if !json["playlists"] || !json["playlists"]["playlist"]
    playlists = json["playlists"]["playlist"]
    playlists = [playlists] if playlists.kind_of?(Hash)
    playlists.map { |p| p["id"] }
  end
  
  # does the dirty work
  def self.http_request(url, parameters = {})
    my_url = url.dup # don't modify the original url reference
    the_params = params_to_string(parameters)
    my_url << '?'+the_params unless the_params !~ /\S/
    
    Net::HTTP.get_response(::URI.parse(my_url)).body
  end
  
  def self.fetch_playlists
    result = {:items => {}, :properties => {} }

    # properties
    PLAYLIST_PROPERTIES.each do |pkey, pdef|
      result[:properties][pkey] = pdef
    end
    
    # get seed artists
    puts "[1] loading seed artists..."
    seed_artists = []

    f = File.open("public/seed_artists.txt", "r")
    f.each_line do |line|
      seed_artists << line.gsub("\n", "")
    end

    # collect top fans of seed artists
    puts "[2] collecting top fans of seed artists..."
    users = []
    seed_artists.each do |a|
      users.concat(PlayList.artist_fans(a)[0..5]) # pick top 5 fans
    end

    # get playlists of fans
    puts "[3] retrieving playlist ids for #{users.length} fans"
    playlists = []

    users.each_with_index do |u, i|
      playlists.concat(PlayList.user_playlists(u))
      print "."
    end
    puts

    puts "[3] retrieving tracks for #{playlists.length} playlists"
    playlists.each do |p|
      pl = PlayList.get(p, seed_artists)
      # only use playlists with at least two songs
      result[:items][p.to_s] = pl.to_hash if pl
      print "."
    end
    
    f = File.open("cache/playlists.json",  "w") do |f|
      f.write(JSON.pretty_generate(result))
    end
    
    IO.read("cache/playlists.json")
  end
  
  # encode parameters
  def self.params_to_string(parameters)
    parameters.keys.map {|k| "#{URI.encode(k.to_s)}=#{URI.encode(parameters[k].to_s)}" }.join('&')
  end
end