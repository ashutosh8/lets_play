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
		if response.code == '200' then
		  tweet = JSON.parse(response.body)
		  puts "Successfully sent #{tweet["text"]}"
		else
		  puts "Could not send the Tweet! " +
		  "Code:#{response.code} Body:#{response.body}"
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
    
    begin
    	puts "Lets Play! What would you like to do?"
    	puts "1. Tweet with my handle"
    	puts "2. Retweet from another handle"
    	puts "3. Retweet from another handle with a specific hashtag"
    	puts "4. Exit"
    	choice = gets.chomp.to_i;
        case choice
        when 1 then
            puts "Please Enter Tweet text:"
            entered_tweet = gets.chomp;
            self.do_tweet(entered_tweet) unless entered_tweet.nil?
            
            puts "Just for fun, would like to retweet your last tweet? (y/n)"
    		ch = gets.chomp;
    		if ch.downcase == 'y' then
                self.do_retweet
            end
        when 2 then
            puts "Please enter a valid Twitter handle:"
            handle = gets.chomp;
            self.do_retweet(handle, nil) unless handle.nil?
        when 3 then
            puts "Please enter a valid Twitter handle:"
            handle = gets.chomp;
            puts "Please enter a hashtag to be present:"
            hashtag = gets.chomp;
            self.do_retweet(handle, hashtag) unless handle.nil? || hashtag.nil?
        when 4 then
            puts "Thank you and Bye!"
        else puts "Thank you and Bye!"
        end

	end while choice != 4
end

