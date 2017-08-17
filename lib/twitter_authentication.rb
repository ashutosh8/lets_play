class TwitterAuthentication
	# Enter the values here:
	@consumer_token = ENV['TWITTER_CONSUMER_KEY']
	@consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
	@callback_url = ENV['TWITTER_CALLBACK_URL']
	@req_method = "POST"
	@oauth_version = "1.0"
	@sig_method = "HMAC-SHA1"

	# The request parameters have also moved to the body
	# of the request instead of being put in the URL.
	@baseurl = "https://api.twitter.com"
	
	def self.gen_nonce_token(size=32)
		nonce_token = Base64.encode64(OpenSSL::Random.random_bytes(size)).gsub(/\W/, '')
		return nonce_token
	end
	
	# sort (very important as it affects the signature), concat, and percent encode all params
    # @ref http://oauth.net/core/1.0/#rfc.section.9.1.1
    # @ref http://oauth.net/core/1.0/#9.2.1
    # @ref http://oauth.net/core/1.0/#rfc.section.A.5.1
    def self.query_string
	    pairs = []
	    @params.sort.each { | key, val | 
	      pairs.push( "#{  OAuth::Helper::escape( key ) }=#{ ( val.to_s ) }" )
	    }
	    pairs.join '&'
    end
	
	def self.gen_oauth_signature(address, token_secret=nil)
		key = OAuth::Helper::escape( @consumer_secret ) + '&' + (token_secret.nil? == true ? "" : (OAuth::Helper::escape(token_secret)))
		req_url = OAuth::Helper::escape(address.to_s)
		
		# create base string
	    # ref http://oauth.net/core/1.0/#anchor14
	    @base_string = [ 
		    @req_method, 
		    req_url,
		    OAuth::Helper::escape( self.query_string ) 
    	].join( '&' )
		
		digest = OpenSSL::Digest.new( 'sha1' )
	    hmac = OpenSSL::HMAC.digest( digest, key, @base_string  )
	    signature = Base64.encode64( hmac ).chomp.gsub( /\n/, '' )
	    return signature
	end
	
	def self.build_authorization_string(is_callback)
		auth_string = ("OAuth " + "oauth_consumer_key=" + @params['oauth_consumer_key'] + ", oauth_nonce=" + @params['oauth_nonce'] +
					  ", oauth_signature=" + @params['oauth_signature'] + ", oauth_signature_method=" + @params['oauth_signature_method'] +
					   ", oauth_timestamp=" + @params['oauth_timestamp'] + ( is_callback == true ? (", oauth_callback=" + @params['oauth_callback'])
					   : (", oauth_token=" + @params['oauth_token'] + ", oauth_verifier=" + @params['oauth_verifier']) ) + ", oauth_version=" + @params['oauth_version']) unless @params.nil?
		return auth_string
	
	end
	
	def self.request_token_from_twitter
	   begin
		path    = "/oauth/request_token"
		address = URI("#{@baseurl}#{path}")
		request = Net::HTTP::Post.new address.request_uri
		
	    # Set up HTTP.
		http             = Net::HTTP.new address.host, address.port
		http.use_ssl     = true
		http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	
		@params = {
	      'oauth_consumer_key' =>  OAuth::Helper::escape(@consumer_token),
	      'oauth_nonce' =>  OAuth::Helper::escape(gen_nonce_token),
	      'oauth_signature_method' =>  OAuth::Helper::escape(@sig_method),
	      'oauth_timestamp' =>  OAuth::Helper::escape(Time.now.utc.to_i.to_s),
	      'oauth_version' =>  OAuth::Helper::escape(@oauth_version),
	      'oauth_callback' => OAuth::Helper::escape(@callback_url)
	    }
	    @params['oauth_signature'] =  OAuth::Helper::escape(gen_oauth_signature(address))
	    
		request["content-type"] = "application/x-www-form-urlencoded"
		request["authorization"] = self.build_authorization_string(true)
		
		# Issue the request.
		http.start
		response = http.request request
		
	    if (response.code == '200' && response.body.split('&')[2].split('=')[1].eql?("true"))   #oauth_callback_confirmed == true
			return {msg: response.body, status_code: 200}
		else
		  res_failure = JSON.parse(response.body)
		  failure_msg = res_failure["message"]
		  res_code = res_failure["code"]
		  return {msg: "#{failure_msg}", status_code: "#{res_code}"}			
	    end
	   rescue => e
         puts "#{e.message}"
       end
	end
	
	def self.redirect_to_authenticate(user_token)
		query   = URI.encode_www_form(
			"oauth_token" => user_token,
			"force_login" => true
		)
		
		return "https://api.twitter.com/oauth/authenticate?" + query
	end
	
	def self.access_token_from_twitter(oauth_token, oauth_verifier, token_secret)
	  begin
	   path    = "/oauth/access_token"
	   address = URI("#{@baseurl}#{path}")
	   request = Net::HTTP::Post.new address.request_uri
		
	   # Set up HTTP.
	   http             = Net::HTTP.new address.host, address.port
	   http.use_ssl     = true
	   http.verify_mode = OpenSSL::SSL::VERIFY_PEER

	   @params = {
	      'oauth_consumer_key' =>  OAuth::Helper::escape(@consumer_token),
	      'oauth_nonce' =>  OAuth::Helper::escape(gen_nonce_token),
	      'oauth_signature_method' =>  OAuth::Helper::escape(@sig_method),
	      'oauth_timestamp' =>  OAuth::Helper::escape(Time.now.utc.to_i.to_s),
	      'oauth_token' => OAuth::Helper::escape(oauth_token),
	      'oauth_version' =>  OAuth::Helper::escape(@oauth_version),
	      'oauth_verifier' => OAuth::Helper::escape(oauth_verifier)
	   }
	   @params['oauth_signature'] =  OAuth::Helper::escape(gen_oauth_signature(address, token_secret))
	  
	   request["content-type"] = "application/x-www-form-urlencoded"
	   request["authorization"] = self.build_authorization_string(false)
	   request["oauth_verifier"] = OAuth::Helper::escape(oauth_verifier)
		
	   # Issue the request.
	   http.start
	   response = http.request request
		
	   if (response.code == '200')
	    	return {msg: response.body, status_code: 200}
	   end
	  rescue => e
         puts "#{e.message}"
      end	  
	end
end