require 'rubygems'
require 'ken'
require 'sinatra'
require 'json'
require 'typhoeus'

require 'playlist'

require 'country'


get '/' do
  'This service provides some collections:<br/>
  <ul>
    <li><a href="/countries">Countries</a> source (freebase.com, data.worldbank.org) </li>
    <li><a href="/playlists">Playlists from Last.fm</a> (<a href="/seed_artists.txt">Seed Artists used</a>)</li>
  </ul>
  '
end


get '/update_countries' do
  Country.fetch_countries
end

get '/countries' do
  IO.read("cache/countries.json")
end

get '/update_playlists' do
  PlayList.fetch_playlists
end

get '/playlists' do
  from_cache = IO.read("cache/playlists.json")
  from_cache.empty? ? PlayList.fetch_playlists : from_cache
end
