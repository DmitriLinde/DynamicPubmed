class DynamicPubmedController < ApplicationController
  def home
  	
  	@LogicModel = Query.new

  	# If User Entered Search Parameter, Query Pubmed
  	if params[:search]
  		@query = params[:search]
  		# Query Pubmed
		@results = @LogicModel.search(@query)

		# IF user has also liked an item, augment results
		if params[:liked]
			@userLiked = params[:liked]
			@newQuery = @LogicModel.like(@userLiked, @query)
		end
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
