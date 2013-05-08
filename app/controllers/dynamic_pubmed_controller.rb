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
			@returned = @LogicModel.Like(@userLiked, @query)

			@newQuery = @returned[0]
			@mhList = @returned[1]
			@genotype = @returned[2]
		elsif params[:evolving]
			if params[:evolving] == "1"
				# update @newQuery
				mhList = params[:mhList].split('|')
				genotype = params[:genotype].split('|')
				@newQuery = @LogicModel.NextGeneration(params[:origQuery], mhList, genotype)
			end
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
