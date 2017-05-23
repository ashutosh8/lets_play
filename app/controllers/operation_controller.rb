require 'twitter_utility'

class OperationController < ApplicationController
    def new
       
    end
    
    def tweet
      if(!params[:entered_tweet].blank?)
        @res = TwitterUtility::do_tweet(params[:entered_tweet])
        if @res[:status_code]==200
          flash[:notice] = @res[:msg]
        else
          flash[:alert] = @res[:msg]
        end
        redirect_to operation_new_path
      else
        flash[:notice] = "Please enter your tweet!"
        redirect_to operation_new_path
      end
        
    end

end
