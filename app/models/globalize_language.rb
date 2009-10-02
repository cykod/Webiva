# Copyright (C) 2009 Pascal Rettig.

class GlobalizeLanguage < SystemModel 

	def self.find_common
		self.find(:all,:conditions => 'Iso_639_1 is not null',:order => 'english_name')
	end

end