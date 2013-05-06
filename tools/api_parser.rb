

response = {"im_off"=>0, "events"=>[{"server_gmt"=>1366140607, "to"=>"0", "server_seqid"=>2680688314, "type"=>"toolbar_trigger", "contents"=>""}, {"server_gmt"=>1366140607, "to"=>"0", "server_seqid"=>2680688314, "type"=>"toolbar_trigger", "contents"=>""}, {"server_gmt"=>1366140607, "from"=>"***REMOVED***", "server_seqid"=>2680688315, "type"=>"msg_notify", "contents"=>""}], "num_unread"=>7, "server_gmt"=>1366140611, "people"=>[{"enemy"=>0, "is_buddy"=>0, "open_connection"=>1, "im_ok"=>1, "gender"=>"M", "location"=>"Allston, Massachusetts", "userid"=>"6446984563039079031", "match"=>82, "orientation"=>"B", "age"=>27, "distance"=>0, "friend"=>61, "is_online"=>1, "screenname"=>"***REMOVED***", "thumb"=>"0x8/327x475/2/7781864178700995443.jpeg"}], "server_seqid"=>2680688315}
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
