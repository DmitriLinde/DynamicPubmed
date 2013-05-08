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
			@likedIndex = params[:liked].to_i
			@likeResults = @LogicModel.like(@likedIndex, @query)

			@results = @likeResults[0]
			@newQuery = @likeResults[1]
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
