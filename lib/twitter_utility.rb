require 'rubygems'
require 'oauth'
require 'json'

class TwitterUtility
	# You will need to set your application type to
	# read/write on dev.twitter.com and regenerate your access
	# token.  Enter the values here:
	@consumer_key = OAuth::Consumer.new(ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET'])
	@access_token = OAuth::Token.new(ENV['TWITTER_ACCESS_TOKEN'], ENV['TWITTER_ACCESS_TOKEN_SECRET'])

	# The request parameters have also moved to the body
	# of the request instead of being put in the URL.
	@baseurl = "https://api.twitter.com"

	def self.do_tweet(entered_tweet)
		path    = "/1.1/statuses/update.json"
		address = URI("#{@baseurl}#{path}")
		request = Net::HTTP::Post.new address.request_uri
		request.set_form_data(
		  "status" => entered_tweet,
		)


		# Set up HTTP.
		http             = Net::HTTP.new address.host, address.port
		http.use_ssl     = true
		http.verify_mode = OpenSSL::SSL::VERIFY_PEER

		# Issue the request.
		request.oauth! http, @consumer_key, @access_token
		http.start
		response = http.request request

		# Parse the Tweet if the response code was 200
		tweet = nil
		failure_msg = nil
		res_code = 0
		if response.code == '200' then
		  tweet = JSON.parse(response.body)
		  return {msg: "Successfully sent #{tweet["text"]}", status_code: 200}
		else
		  res_failure = JSON.parse(response.body)
		  binding.pry
		  res_failure["errors"].each do |err|
		  	failure_msg = err["message"]
		  	res_code = err["code"]
		  	break;
		  end
		  return {msg: "#{failure_msg}", status_code: "#{res_code}"}
		end
	end


	def self.do_retweet(handle="Ashutosh_indeed", hashtag=nil)
		
		if hashtag.nil?
			tweet_id = self.get_last_tweet_id(handle)
		else 
			tweet_id = self.get_last_tweet_id_hashtag(handle, hashtag)
			if tweet_id.nil?
				puts "Tweet with entered hashtag does not appear to be recent or popular or is not present in the user's timeline."
				return
			end
		end

		path = "/1.1/statuses/retweet/#{tweet_id}.json"
		address = URI("#{@baseurl}#{path}")
		request = Net::HTTP::Post.new address.request_uri


		# Set up HTTP.
		http             = Net::HTTP.new address.host, address.port
		http.use_ssl     = true
		http.verify_mode = OpenSSL::SSL::VERIFY_PEER

		# Issue the request.
		request.oauth! http, @consumer_key, @access_token
		http.start
		response = http.request request

		# Parse the Tweet if the response code was 200
		tweet = nil
		if response.code == '200' then
		  tweet = JSON.parse(response.body)
		  puts "Successfully sent #{tweet["text"]}"
		else
		  puts "Could not send the Re-Tweet! " +
		  "Code:#{response.code} Body:#{response.body}"
		end
	end
	

	def self.get_last_tweet_id(handle)

		# Now you will fetch /1.1/statuses/user_timeline.json,
		# returns a list of public Tweets from the specified
		# account.
		path    = "/1.1/statuses/user_timeline.json"
		query   = URI.encode_www_form(
		    "screen_name" => handle,
		    "count" => 1,
		    "include_rts" => false
		)
		address = URI("#{@baseurl}#{path}?#{query}")
		request = Net::HTTP::Get.new address.request_uri


		# Set up HTTP.
		http             = Net::HTTP.new address.host, address.port
		http.use_ssl     = true
		http.verify_mode = OpenSSL::SSL::VERIFY_PEER

		# Issue the request.
		request.oauth! http, @consumer_key, @access_token
		http.start
		response = http.request request

		# Parse and print the Tweet if the response code was 200
		tweets = nil
		if response.code == '200' then
		  tweets = JSON.parse(response.body)
		  tweet_id = self.traverse_timeline(tweets)
		end

		return tweet_id
	end

	def self.get_last_tweet_id_hashtag(handle, hashtag)

		# Now you will fetch /1.1/statuses/user_timeline.json,
		# returns a list of public Tweets from the specified
		# account with a specified hashtag.
		path    = "/1.1/search/tweets.json"
		query   = "q=from%3A" + handle + "%20%23" + hashtag + "&count=10"
		
		address = URI("#{@baseurl}#{path}?#{query}")
		request = Net::HTTP::Get.new address.request_uri
		#puts "#{@baseurl}#{path}?#{query}"

		# Set up HTTP.
		http             = Net::HTTP.new address.host, address.port
		http.use_ssl     = true
		http.verify_mode = OpenSSL::SSL::VERIFY_PEER

		# Issue the request.
		request.oauth! http, @consumer_key, @access_token
		http.start
		response = http.request request

		# Parse and print the Tweet if the response code was 200
		res_json = nil
		if response.code == '200' then
		  res_json = JSON.parse(response.body)
		  if(res_json["statuses"].length > 0)
			tweet_id = self.traverse_timeline_search(res_json)
		  end
		  else
		  	tweet_id = nil
		end

		return tweet_id
	end

	def self.traverse_timeline(tweets)
			tweet_id = nil
			  tweets.each do |tweet|
			  	tweet_id = tweet["id"]
			  	break;
			  end
	  return tweet_id;
	end
	
	def self.traverse_timeline_search(res_json)
			tweet_id = nil
			  res_json["statuses"].each do |status|
			  	tweet_id = status["id"]
			  	break;
			  end
	  return tweet_id;
	end
end

