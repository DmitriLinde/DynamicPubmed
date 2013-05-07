class Query < ActiveRecord::Base
  attr_accessible :value
  validates_presence_of :value

  def self.search(search)
  	if not search.empty?
  		# return array of articles
  		
  	end
  end
end
