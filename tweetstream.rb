require 'rubygems'
require 'sinatra'
require 'em-http'
require 'json'


get '/tweets' do
	content_type 'text/html', :charset => 'utf-8'
	TWEETS.map {|tweet| 
	if tweet then
	"<p><b>#{tweet['user']}</b>: #{tweet['text']}</p>"
	end
	}.join
end

get '/search.json/:query' do 
	headers 'Access-Control-Allow-Origin' => '*'
	query = params[:query]
	URI.unescape(query)
	query_time = Time.now - 5 ##Five seconds before request was received
	results = Array.new
	TWEETS.map {|tweet|
	if (tweet['text'].downcase.include? query.downcase) && ((query_time <=> tweet['created_at']) < 0) then
		results.push(tweet)
	end
	}
	content_type 'json'
	rate_appr = results.length
	results.to_json
end
	

get '/server.json/' do
	content_type 'json'
	TWEETS.to_json
end

MAX_STORE = 1000
TWEETS = Array.new
STREAM_URL = 'https://stream.twitter.com/1.1/statuses/filter.json?locations=-124.848974,24.396308,-66.885444,49.384358'
USERNAME = ######
PASSWORD = ######

def handle_tweet(tweet)
	return unless tweet['text']
	tweet_obj = {'user' => tweet['user']['screen_name'], 'text' => tweet['text'], 'created_at' => Time.now, 'pic' => tweet['user']['profile_image_url']}
	if TWEETS.length < MAX_STORE then
		TWEETS.push(tweet_obj)
	else 
		TWEETS.shift
		TWEETS.push(tweet_obj)
	end
end

EM.schedule do
  http = EM::HttpRequest.new(STREAM_URL).get :head => { 'Authorization' => [ USERNAME, PASSWORD ] }
  buffer = ""
  http.stream do |chunk|
    buffer += chunk
    while line = buffer.slice!(/.+\r?\n/)
      handle_tweet JSON.parse(line)
    end
  end
end

