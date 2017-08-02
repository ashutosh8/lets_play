require 'rubygems'
require 'oauth'
require 'openssl'
require 'base64'
require 'json'

class TwitterAuthentication < ActionDispatch::Session::CookieStore
	# You will need to set your application type to
	# read/write on dev.twitter.com and regenerate your access
	# token.  Enter the values here:
	@consumer_token = ENV['TWITTER_CONSUMER_KEY']
	@consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
	@callback_url = "https://twiapi-ashutosh3aces.c9users.io/auth/callback"
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
	
	# sort (very important as it affects the signature), concat, and percent encode
    # @ref http://oauth.net/core/1.0/#rfc.section.9.1.1
    # @ref http://oauth.net/core/1.0/#9.2.1
    # @ref http://oauth.net/core/1.0/#rfc.section.A.5.1
    def self.query_string
	    pairs = []
	    @params.sort.each { | key, val | 
	      pairs.push( "#{  OAuth::Helper::escape( key ).gsub('*', '%2A') }=#{ ( val.to_s ) }" )
	    }
	    pairs.join '&'
    end
	
	def self.gen_oauth_signature(address, token_secret=nil)
		key = OAuth::Helper::escape( @consumer_secret ).gsub('*', '%2A') + '&' + (token_secret.nil? == true ? "" : (OAuth::Helper::escape(token_secret).gsub('*', '%2A')))
		req_url = OAuth::Helper::escape(address.to_s).gsub('*', '%2A')
		
		# create base str. make it an object attr
	    # ref http://oauth.net/core/1.0/#anchor14
	    @base_string = [ 
		    @req_method, 
		    req_url, 
		    # normalization is just x-www-form-urlencoded
		    OAuth::Helper::escape( self.query_string ) 
    	].join( '&' )
		
		digest = OpenSSL::Digest.new( 'sha1' )
	    hmac = OpenSSL::HMAC.digest( digest, key, @base_string  )
	    signature = Base64.encode64( hmac ).chomp.gsub( /\n/, '' )
	    return signature
	end
	
	def self.build_authorization_string(is_callback)
		auth_string = "OAuth " + "oauth_consumer_key=" + @params['oauth_consumer_key'] + ", oauth_nonce=" + @params['oauth_nonce'] +
					  ", oauth_signature=" + @params['oauth_signature'] + ", oauth_signature_method=" + @params['oauth_signature_method'] +
					   ", oauth_timestamp=" + @params['oauth_timestamp'] + ( is_callback == true ? (", oauth_callback=" + @params['oauth_callback'])
					   : (", oauth_token=" + @params['oauth_token'] + ", oauth_verifier=" + @params['oauth_verifier']) ) + ", oauth_version=" + @params['oauth_version']
	
	end
	
	def self.request_token_from_twitter
		path    = "/oauth/request_token"
		address = URI("#{@baseurl}#{path}")
		request = Net::HTTP::Post.new address.request_uri
		
	    # Set up HTTP.
		http             = Net::HTTP.new address.host, address.port
		http.use_ssl     = true
		http.verify_mode = OpenSSL::SSL::VERIFY_PEER

		@params = {
	      'oauth_consumer_key' =>  OAuth::Helper::escape(@consumer_token).gsub('*', '%2A'),
	      'oauth_nonce' =>  OAuth::Helper::escape(gen_nonce_token).gsub('*', '%2A'),
	      'oauth_signature_method' =>  OAuth::Helper::escape(@sig_method).gsub('*', '%2A'),
	      'oauth_timestamp' =>  OAuth::Helper::escape(Time.now.utc.to_i.to_s).gsub('*', '%2A'),
	      'oauth_version' =>  OAuth::Helper::escape(@oauth_version).gsub('*', '%2A'),
	      'oauth_callback' => OAuth::Helper::escape(@callback_url).gsub('*', '%2A')
	    }
	    @params['oauth_signature'] =  OAuth::Helper::escape(gen_oauth_signature(address)).gsub('*', '%2A')
	    
	    #binding.pry
		request["content-type"] = "application/x-www-form-urlencoded"
		request["authorization"] = self.build_authorization_string(true)
		# Issue the request.
		http.start
		response = http.request request
		
	    if (response.code == '200' && response.body.split('&')[2].split('=')[1].eql?("true"))   #oauth_callback_confirmed == true
			# session[:user_token] = response.body.split('&')[0].split('=')[1]
			# session[:user_token_secret] = response.body.split('&')[1].split('=')[1]
			return response
			#binding.pry
			# self.request_access_token_from_twitter
			# redirect_to @request_token.authorize_url
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
	
		path    = "/oauth/access_token"
		address = URI("#{@baseurl}#{path}")
		request = Net::HTTP::Post.new address.request_uri
		
	    # Set up HTTP.
		http             = Net::HTTP.new address.host, address.port
		http.use_ssl     = true
		http.verify_mode = OpenSSL::SSL::VERIFY_PEER

		@params = {
	      'oauth_consumer_key' =>  OAuth::Helper::escape(@consumer_token).gsub('*', '%2A'),
	      'oauth_nonce' =>  OAuth::Helper::escape(gen_nonce_token).gsub('*', '%2A'),
	      'oauth_signature_method' =>  OAuth::Helper::escape(@sig_method).gsub('*', '%2A'),
	      'oauth_timestamp' =>  OAuth::Helper::escape(Time.now.utc.to_i.to_s).gsub('*', '%2A'),
	      'oauth_token' => OAuth::Helper::escape(oauth_token).gsub('*', '%2A'),
	      'oauth_version' =>  OAuth::Helper::escape(@oauth_version).gsub('*', '%2A'),
	      'oauth_verifier' => OAuth::Helper::escape(oauth_verifier).gsub('*', '%2A')
	    }
	    @params['oauth_signature'] =  OAuth::Helper::escape(gen_oauth_signature(address, token_secret)).gsub('*', '%2A')
	    
	    #binding.pry
		request["content-type"] = "application/x-www-form-urlencoded"
		request["authorization"] = self.build_authorization_string(false)
		request["oauth_verifier"] = OAuth::Helper::escape(oauth_verifier).gsub('*', '%2A')
		
		# Issue the request.
		http.start
		response = http.request request
		#binding.pry
	    if (response.code == '200')
			return response
	    end
	end
	
end