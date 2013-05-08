class Query < ActiveRecord::Base	
	attr_accessible :value
	validates_presence_of :value

	def initialize()
		@dp = DynamicPubmed.new
	end

	def search(search)
		if not search.empty?
			# return array of articles
			return @dp.main(search)
		end
	end

	def Like(liked, query)
		likedPMIDs = Array.new
		temp = liked.split(',')
		temp.each {|elt| likedPMIDs.push(elt)}

		results = @dp.like(likedPMIDs)

		if likedPMIDs.length == 1
			# get most liked article's mesh headers
			mhs = results[0][:meshHeaders]
			
			genotype = Array.new
			genotype = (([nil]*mhs.length).each {|i| genotype.push(i)}).fill { |i| (rand*5).round }

			# at least one bit must be 1
			sum = 0
			genotype.each {|bit| sum += bit}
			if sum < 1
				genotype[(rand*genotype.length).floor] = 1
			end

			queryAugmentMHs = Array.new
			queryAugmentMHs = (results[0][:meshHeaders]).select { |mh| genotype[(results[0][:meshHeaders]).index(mh)] == 1 }


			updateString = queryAugmentMHs.join('"[mh] OR "').concat('"').insert(0, ' OR "') + "[mh]"
			evolutionQuery = query + updateString

			return evolutionQuery, results[0][:meshHeaders], genotype
		else
			# get each liked article's mesh headers
			mhs = Array.new
			numLiked = likedPMIDs.length - 1
			for i in 0..numLiked
				mhs.push(results[i][:meshHeaders])
			end

			# record common hesh headers
			uniqueMHs = Array.new
			for i in 0..(mhs.length-1)
				for j in 0..(mhs[i].length-1)
					if !uniqueMHs.include? mhs[i][j]
						uniqueMHs.push(mhs[i][j])
					end
				end
			end

			# continue algorithm
			genotype = Array.new
			genotype = (([nil]*uniqueMHs.length).each {|i| genotype.push(i)}).fill { |i| (rand*5).round }

			# at least one bit must be 1
			sum = 0
			genotype.each {|bit| sum += bit}
			if sum < 1
				genotype[(rand*genotype.length).floor] = 1
			end

			queryAugmentMHs = Array.new
			queryAugmentMHs = (uniqueMHs).select { |mh| genotype[(uniqueMHs).index(mh)] == 1 }


			updateString = queryAugmentMHs.join('"[mh] OR "').concat('"').insert(0, ' OR "') + "[mh]"
			evolutionQuery = query + updateString

			return evolutionQuery, uniqueMHs, genotype
		end
	end

	def NextGeneration(origQuery, mhList, genotype)
		for i in 0..(genotype.length-1)
			genotype[1] = (rand*5).round
		end

		queryAugmentMHs = Array.new
		queryAugmentMHs = (mhList).select { |mh| genotype[(mhList).index(mh)] == 1 }


		updateString = queryAugmentMHs.join('"[mh] OR "').concat('"').insert(0, ' OR "') + "[mh]"
		evolutionQuery = origQuery + updateString

		return evolutionQuery
	end
end

# ----------------------------------------------------------------------------
# ------- SCRIPT LOGIC

#! /usr/local/bin/ruby
=begin
Name: 			CS 295 Final Project Script Logic
Description:	Browser Version of Final Project

Author: 		Dmitri Linde
Created:		4/10/13
=end

# User Editable Parameters ###########################################################
MAX_RESULTS = 20
HILL_CLIMBER_MUTATE_PROBABILITY = 20 # percent chance algorithm will augment genotype
######################################################################################

# Create Structure to store each PubMed Article (POD class)
Result = Struct.new(:pmid, :authors, :title, :ab, :so, :score, :meshHeaders)

class DynamicPubmed
	def initialize() # initialize variables
		# Create Array to hold @Results
		@Results = Array.new
		
		# Set default email address for E-utilities
		Bio::NCBI.default_email = "dlinde@uvm.edu"

		# Evolution parameters
		@evolutionQuery
	end

	def main(*args)
		#args[0]: QUERY

		@evolutionQuery = args[0]

		pmid_list = search()				# get list of PMIDs from PubMed
		efetchResults = fetch(pmid_list)	# get data for PMIDs from PubMed
		parse(efetchResults)				# parse fetch results

		# Sort Results by User Fitness
		@Results.sort! {|a,b| b[:score] <=> a[:score]}

		return @Results
	end

	def like(likedPMIDs)
		likedIndeces = Array.new
		for i in 0..(likedPMIDs.length-1)
			for j in 0..(@Results.length-1)
				if likedPMIDs[i] == @Results[j][:pmid]
					@Results[j][:score] += 1
				end
			end
		end

		# Sort Results by User Fitness
		@Results.sort! {|a,b| b[:score] <=> a[:score]}

		return @Results
	end

	def search()
		### [Summary]: 
		###		Searches PubMed by query from user
		### [requires]:
		###		Ruby 'bio' gem
		###	[returns]: 
		###		Array of PMIDs from PubMed search
		###			[Array of String]
		
		# Instantiate new ncbi_search variable
		ncbi_search = Bio::NCBI::REST::ESearch.new
		
		# eSEARCH PMID List for Query
		return ncbi_search.search("pubmed", @evolutionQuery, MAX_RESULTS - @Results.length)
	end

	def fetch(pmid_list)
		### [Summary]: 
		###		Returns data for an array of PMIDs from PubMed
		### [requires]:
		###		Ruby 'bio' gem
		### [arguments]:
		###		pmid_list - PMIDs returned by search() method
		###			[Array of String]
		###	[returns]: 
		###		MEDLINE format article data
		###			[Array of String]
	
		# Instantiate new ncbi_fetch variable
		ncbi_fetch = Bio::NCBI::REST::EFetch.new
		
		# eFetch @Results for all PMIDS
		efetch_output = ncbi_fetch.pubmed(pmid_list, "medline")
		return efetch_output.split(/\r?\n/)
	end

	def parse(efetchResults)
		### [Summary]: 
		###		Parses data returned by fetch() method
		### [requires]:
		###		...
		### [arguments]:
		###		efetchResults - MEDLINE data returned by fetch()
		###			[Array of String]
		###	[returns]: 
		###		Augments @Results instance variable
	
		# Initialize variables
		first_entry_flag = 0 # Flag for keeping track of first entry
		field = ab = so = authors = pmid = title = ""
		meshHeaders = Array.new

		# Parse MEDLINE output
		efetchResults.each do |line|
		  # Remove newline
		  line.chomp!

		  # Get field name ("PMID", "TI", "MH", etc.)                                                            
		  if line =~ /^([A-Z]+)\s*-/
			field = $1
		  end

		  if line =~ /PMID- ([0-9]*)/
			if first_entry_flag == 1
			  arrayContainsResult = false
			  if @Results.select { |result| result[:pmid] == pmid }.empty?
				@Results.push(Result.new(pmid, authors, title, ab, so, 0, meshHeaders))
			  end
			  ab = so = authors = pmid = title = ""
			  meshHeaders = Array.new
			end
			
			pmid = $1
			first_entry_flag = 1
		  end
		  
		  # Get title                                                                                             
		  # Example: TI  - The treatment of asthma in obesity.                                                     
		  if line =~ /TI  - (.*)/
			title = $1
		  end

		  # Get title - if wraps onto multiple lines                                                               
		  if line =~ /^\s{6}(.*)/ and field.eql?("TI")
			title = title + " " + $1
		  end
		  
		  # Get Authors
		  # Example: AU  - Schneider DJ
		  if line =~ /AU  - (.*)/
			if authors == ""
				authors = $1
			else
				authors += ", " + $1 
			end
		  end
		  
		  # Get SO
		  # Example: SO  - Diabetes Care. 2012 Oct;35(10):1961-7.
		  if line =~ /SO  - (.*)/
			so = $1
		  end
		  
		  if line =~ /^\s{6}(.*)/ and field.eql?("SO")
			so = so + " " + $1
		  end
		  
		  # Get Mesh Headers
		  # Example: MH  - Coronary Artery Bypass/adverse effects
		  if line =~ /MH  - (.*)/
			meshTerm = $1
			meshTerms = meshTerm.split('/') # split meshHeeader from meshTerms
			meshHeader = meshTerms[0]
			if !meshHeaders.include? meshHeader
				meshHeaders.push(meshHeader)
			end
		  end
		  
		  # Get abstract                                                                                             
		  # Example: AB  - OBJECTIVE: The relationship between diseases and their...                                                    
		  if line =~ /AB  - (.*)/
			ab = $1
		  end

		  # Get title - if wraps onto multiple lines                                                               
		  if line =~ /^\s{6}(.*)/ and field.eql?("AB")
			ab = ab + " " + $1
		  end
		end

		# Save Last PubMed Result
		if @Results.select { |result| result[:pmid] == pmid }.empty?
			@Results.push(Result.new(pmid, authors, title, ab, so, 0, meshHeaders))
		end
	end
end