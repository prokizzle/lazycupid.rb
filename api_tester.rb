require './includes'



@debug = false

@log        = Logger.new("logs/#{ARGV[0]}_#{Time.now}.log")

@hash       = Hash.new { |hash, key| hash[key] =  0}
@spotlight  = Hash.new
@messages   = Hash.new
@stalks     = Hash.new
@username   = ARGV[0]

settings    = Settings.new(:username => @username, :path => File.dirname($0) + '/config/')

db          = DatabaseMgr.new(:login_name => @username, :settings => settings)
browser     = Session.new(:username => @username, :password => ARGV[1], :log => @log)
tracker     = EventTracker.new(:browser => browser, :database => db, :settings => settings)
api         = EventWatcher.new(:browser => browser, :tracker => tracker, :logger => Logger.new("logs/#{@username}_#{Time.now}.log"))
print "Logging in... "

if api.login
  puts "Success."
else
  puts "Failed."
end

def print_event_info
  if @debug
    puts "--------------------------"
    print "Event:"
    p @event
    print "People:"
    p @people
    puts "--------------------------"
  end
end

# def msg_notify
#   puts "New message from #{@people["screenname"]}" unless @messages.has_key?(@event["server_gmt"])
#   @messages[@event["server_gmt"]] = @people["screenname"]
#   print_event_info
# end

# def looks_vote

# end

# def stalk
#   # unless @event["server_gmt"].to_i == @last_event_time
#   puts "New visit from #{@people['screenname']}" unless @stalks.has_key?(@event["server_gmt"])
#   @stalks[@event["server_gmt"]] = @people["screenname"]
#   # end
#   # @last_event_time = @event["server_gmt"].to_i
#   print_event_info

# end

# def new_spotlight_user
#   unless @spotlight.has_key?(@event["server_gmt"])
#     puts "New spotlight user: #{@people["screenname"]}"
#     @spotlight[@event["server_gmt"]] = @people["screenname"]
#   end
#   print_event_info
# end

# def toolbar_trigger
#   puts "Toolbar trigger"
#   print_event_info
# end

# def variable_
#   events_array.size.to_i + 1
# end

# def process(event, people)
#   @event = event
#   @people = people
#   type = event["type"]
#   self.send(type)
# end


# begin
# @new_events = Array.new
# @new_people = Array.new
# hash = Hash.new { |hash, key| hash[key] = 0 }
loop do
#   # if app.check_events.respond_to?('each')

#   # puts "Requesting..."
#   temp = app.poll_response
#   # puts "Reponse received."
#   count = 0
#   # puts temp["events"]
#   # puts temp["im_off"]
#   # puts temp["num_unread"]
#   # puts temp["people"]
#   # puts temp["server_seqid"]
#   # puts temp
#   events_array = temp["events"]
#   people_array = temp["people"]
#   events_array_size = events_array.size
#   index = 0
#   people_array.size.to_i.times do
#     current_event_hash = events_array.shift
#     current_people_hash = people_array.shift
#     unless current_event_hash == nil && current_people_hash == nil
#       current_event_hash.merge(current_people_hash)
#       gmt = current_event_hash["server_gmt"]
#       @new_events.push(current_event_hash)
#       @new_people.push(current_people_hash)
#       unless hash.has_key?(gmt.to_i)
#         x_temp = @new_events.shift
#         y_temp = @new_people.shift
#         # puts "Processing: #{x_temp}","for #{current_people_hash["screenname"]} who is #{current_event_hash["from"]}"
#         process(x_temp, y_temp)
#       end
#       hash[gmt.to_i] = current_event_hash
#       # puts hash
#       sleep 4
#     end
api.check_events
  # end
end
