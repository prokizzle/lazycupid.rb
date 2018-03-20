

response = {"im_off"=>0, "events"=>[{"event_arg1"=>"", "type"=>"orbit_user_signoff", "event_objectid"=>"0", "event_arg4"=>"", "server_seqid"=>2671146057, "event_id"=>"11", "from"=>"felixtrickster", "event_user_gender"=>"2", "event_arg2"=>"", "event_username"=>"felixtrickster", "server_gmt"=>1385939098, "event_arg3"=>""}], "num_drafts"=>0, "server_seqid"=>2671146057, "num_spam_unread"=>0, "people"=>[{"enemy"=>17, "is_buddy"=>0, "open_connection"=>1, "im_ok"=>1, "gender"=>"F", "location"=>"Providence, Rhode Island", "userid"=>"12189458661582598434", "match"=>91, "orientation"=>"B", "age"=>28, "distance"=>40, "friend"=>65, "is_online"=>0, "screenname"=>"felixtrickster", "thumb"=>"0x171/920x1091/2/15733553948750464886.jpeg"}], "server_gmt"=>1385939098, "num_unread"=>1}
@c = 0
response["events"].each do |event|

  # puts event
  if event.has_key?('from')
    @loc = @c
  end
  @c +=1
  end

  eventz = response["events"][@loc]
  deets = response["people"]

  hash = eventz.merge(deets[deets.size - 1])
  puts hash

  # puts @c
  # puts @real_event
