class DynamicPubmedController < ApplicationController
  def home
  	if params[:search]
  		@query = params[:search]
		@results = Query.search(params[:search])
	else
		@query = ""
	end
  end

  def help
  end

  def about
  end

  def contact
  end
end
