require 'twitter_authentication'

class AuthController < ApplicationController
    def create
        res = TwitterAuthentication::request_token_from_twitter
        session[:user_token] = res.body.split('&')[0].split('=')[1]
	    session[:user_token_secret] = res.body.split('&')[1].split('=')[1]
	    redirect_to TwitterAuthentication::redirect_to_authenticate(session[:user_token].to_s) unless session[:user_token].nil?
    end
    
    def callback
        if (session[:user_token].to_s.eql?(params["oauth_token"].to_s))
            res = TwitterAuthentication::access_token_from_twitter(params["oauth_token"].to_s, params["oauth_verifier"].to_s, session[:user_token_secret].to_s)
            session[:user_token] = res.body.split('&')[0].split('=')[1]
			session[:user_token_secret] = res.body.split('&')[1].split('=')[1]
			session[:user_id] = res.body.split('&')[2].split('=')[1]
			session[:user_screen_name] = res.body.split('&')[3].split('=')[1]
			redirect_to root_path
		else
		    flash[:notice] = "Authorization was unsuccessfull!"	    
		    redirect_to root_path
        end
        # redirect_to root_path
    end
    
    def sign_out
        session[:user_token] = nil
		session[:user_token_secret] = nil
		session[:user_id] = nil
		session[:user_screen_name] = nil
		redirect_to root_path
    end
end
