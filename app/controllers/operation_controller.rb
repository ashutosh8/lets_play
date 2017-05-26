require 'twitter_utility'

class OperationController < ApplicationController
    def new
       
    end
    
    def tweet
      begin
        if(!params[:entered_tweet].blank?)
          @res = TwitterUtility::do_tweet(params[:entered_tweet])
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
      rescue Exception => e
          flash[:alert] = e.message
          redirect_to operation_new_path
      end
    end
    
    def repost
      @is_hashtag_visible = false
    end
    
    def retweet
      begin
        if(!params[:entered_handle].blank?)
          @res = TwitterUtility::do_retweet(params[:entered_handle])
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
      rescue Exception => e
          flash[:alert] = e.message
          redirect_to operation_repost_path   
      end
    end
    
    def retweet
      begin
        if(!params[:entered_handle].blank?)
          @res = TwitterUtility::do_retweet(params[:entered_handle])
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
      rescue Exception => e
          flash[:alert] = e.message
          redirect_to operation_repost_path   
      end
    end
    
    def htrepost
      @is_hashtag_visible = true
      render operation_repost_path
    end
    
    def hashtagrt
      begin
        if(!(params[:entered_handle].blank? && params[:entered_hashtag].blank?))
          @res = TwitterUtility::do_retweet(params[:entered_handle], params[:entered_hashtag])
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
      rescue Exception => e
          flash[:alert] = e.message
          redirect_to operation_htrepost_path   
      end
    end

end
