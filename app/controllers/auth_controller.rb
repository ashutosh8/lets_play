require 'twitter_authentication'

class AuthController < ApplicationController
    def create
       begin
        res = TwitterAuthentication::request_token_from_twitter
        if res[:status_code] == 200
            session[:user_token] = res[:msg].split('&')[0].split('=')[1]
    	    session[:user_token_secret] = res[:msg].split('&')[1].split('=')[1]
    	    redirect_to TwitterAuthentication::redirect_to_authenticate(session[:user_token].to_s) unless session[:user_token].nil?
    	else
            flash[:alert] = res[:msg]
    	end
       rescue => e
          flash[:alert] = e.message
          redirect_to root_path
       end
    end
    
    def callback
      begin
        if (session[:user_token].to_s.eql?(params["oauth_token"].to_s))
         res = TwitterAuthentication::access_token_from_twitter(params["oauth_token"].to_s, params["oauth_verifier"].to_s, session[:user_token_secret].to_s)
         if res[:status_code] == 200
             session[:user_token] = res[:msg].split('&')[0].split('=')[1]
    		 session[:user_token_secret] = res[:msg].split('&')[1].split('=')[1]
    		 session[:user_id] = res[:msg].split('&')[2].split('=')[1]
    		 session[:user_screen_name] = res[:msg].split('&')[3].split('=')[1]
    		 session[:access_token] = {token: session[:user_token].to_s, secret: session[:user_token_secret].to_s}
    		 redirect_to root_path
    		 flash[:notice] = "Logged in successfully!"
    	 else
             flash[:alert] = res[:msg]
    	 end
		else
		    flash[:alert] = "Authorization was unsuccessfull!"	    
		    redirect_to root_path
        end
      rescue => e
          flash[:alert] = e.message
          redirect_to root_path
      end
    end
    
    def sign_out
      begin
        session[:user_token] = nil
		session[:user_token_secret] = nil
		session[:user_id] = nil
		session[:user_screen_name] = nil
		session[:access_token] = nil
		redirect_to root_path
	  rescue => e
          flash[:alert] = e.message
          redirect_to root_path
      end	
    end
end
