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
    		 if(User.exists?(twi_id: session[:user_id]))
    		     @db_user_id = User.find_by(twi_id: session[:user_id])
        		 @user = User.update(@db_user_id.id, {last_login_at: DateTime.now})
    		 else
    		     @user = User.new({twi_id: session[:user_id], twi_screen_name: session[:user_screen_name], last_login_at: DateTime.now})
        		 @user.save
    		 end
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
        reset_session
		redirect_to root_path
	  rescue => e
          flash[:alert] = e.message
          redirect_to root_path
      end	
    end
end