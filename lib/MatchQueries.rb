class MatchQueries

  def focus_new_users_query
    "http://www.okcupid.com/match?filter1=0,34&filter2=2,19,29&filter3=3,25&filter4=5,604800&filter5=1,1&filter6=35,2&filter7=6,604800&filter8=10,0,16510&locid=0&timekey=1&matchOrderBy=JOIN&custom_search=0&fromWhoOnline=0&mygender=m&update_prefs=1&sort_type=0&sa=1&ajax_load=1"
  end

  def default_query
    "http://www.okcupid.com/match?timekey=#{Time.now.to_i}&matchOrderBy=SPECIAL_BLEND&use_prefs=1&discard_prefs=1&low=11&count=10&&filter7=6,604800&ajax_load=1"
  end

end
