module LazyCupid
  class MatchQueries
    require 'uri'

    def self.random_sort
      ['JOIN', 'MATCH', 'SPECIAL_BLEND', 'LOGIN', 'MATCH_AND_NEW', 'MATCH_AND_LOGIN', 'MATCH_AND_DISTANCE'].shuffle.sample
    end

    def focus_new_users_query
      URI.escape("http://www.okcupid.com/match?filter1=0,34&filter2=2,19,29&filter3=3,25&filter4=5,604800&filter5=1,1&filter6=35,2&filter7=6,604800&filter8=10,0,16510&locid=0&timekey=1&matchOrderBy=JOIN&custom_search=0&fromWhoOnline=0&mygender=m&update_prefs=1&sort_type=0&sa=1&ajax_load=1")
    end

    # def self.default_query
    #   URI.escape("http://www.okcupid.com/match?timekey=#{Time.now.to_i}&matchOrderBy=MATCH&use_prefs=1&discard_prefs=1&low=11&count=10&&filter7=6,604800&ajax_load=1")
    # end

    def self.default_query
      URI.escape("http://www.okcupid.com/match?timekey=1&matchOrderBy=#{random_sort}&use_prefs=1&discard_prefs=1&count=18&ajax_load=1")
    end



    def self.unicorn_query
      URI.escape("http://www.okcupid.com/match?filter1=0,32&filter2=2,18,49&filter3=3,500&filter4=5,2678400&filter5=35,12&filter6=6,2678400&filter7=32,64&filter8=1,1&locid=0&timekey=1&matchOrderBy=#{random_sort}&custom_search=0&fromWhoOnline=0&mygender=m&update_prefs=1&sort_type=0&sa=1&using_saved_search=&count=18&ajax_load=1")
    end

  end
  module Queries
    def self.default_query
      "http://www.okcupid.com/match?timekey=#{Time.now.to_i}&matchOrderBy=MATCH&use_prefs=1&discard_prefs=1&low=11&count=10&&filter7=6,604800&ajax_load=1"
    end
  end
end
