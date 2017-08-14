require 'twitter_utility'

class OperationController < ApplicationController
  
    def new
      if(session[:user_id].nil?)
        flash[:alert] = "Please Sign with Twitter credentials"
        redirect_to root_path 
      end
    end
    
    def tweet
      begin
        if(!params[:entered_tweet].blank?)
          @res = TwitterUtility::do_tweet(params[:entered_tweet], session[:access_token])
          if @res[:status_code] == 200
            flash[:notice] = @res[:msg]
          else
            flash[:alert] = @res[:msg]
          end
          redirect_to operation_new_path
        else
          flash[:notice] = "Please enter your tweet!"
          redirect_to operation_new_path
        end
      rescue => e
          flash[:alert] = e.message
          redirect_to operation_new_path
      end
    end
    
    def repost
       if(session[:user_id].nil?)
        flash[:alert] = "Please Sign with Twitter credentials"
        redirect_to root_path 
      else
        @is_hashtag_visible = false
      end
    end
    
    def retweet
      begin
        if(!params[:entered_handle].blank?)
          @res = TwitterUtility::do_retweet(params[:entered_handle], session[:access_token])
          if @res[:status_code] == 200
            flash[:notice] = @res[:msg]
          else
            flash[:alert] = @res[:msg]
          end
          redirect_to operation_repost_path
        else
          flash[:notice] = "Please enter a twitter handle!"
          redirect_to operation_repost_path
        end
      rescue => e
          flash[:alert] = e.message
          redirect_to operation_repost_path   
      end
    end
    
    def htrepost
      if(session[:user_id].nil?)
        flash[:alert] = "Please Sign with Twitter credentials"
        redirect_to root_path 
      else
      @is_hashtag_visible = true
      render operation_repost_path
      end
    end
    
    def hashtagrt
      begin
        if(!(params[:entered_handle].blank? && params[:entered_hashtag].blank?))
          @res = TwitterUtility::do_retweet(params[:entered_handle], params[:entered_hashtag], session[:access_token])
          if @res[:status_code] == 200
            flash[:notice] = @res[:msg]
          else
            flash[:alert] = @res[:msg]
          end
          redirect_to operation_htrepost_path
        else
          flash[:notice] = "Please enter both the twitter handle and the required hashtag!"
          redirect_to operation_htrepost_path
        end
      rescue => e
          flash[:alert] = e.message
          redirect_to operation_htrepost_path   
      end
    end

end
