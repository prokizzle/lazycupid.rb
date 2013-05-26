require './includes'



@debug = false

@log        = Logger.new("logs/#{ARGV[0]}_#{Time.now}.log")

@hash       = Hash.new { |hash, key| hash[key] =  0}
@spotlight  = Hash.new
@messages   = Hash.new
@stalks     = Hash.new
@username   = ARGV[0]
@people_hash = Hash.new

settings    = Settings.new(:username => @username, :path => File.dirname($0) + '/config/')

db          = DatabaseMgr.new(:login_name => @username, :settings => settings)
browser     = Browser.new(:username => @username, :password => ARGV[1], :log => @log)
tracker     = EventTracker.new(:browser => browser, :database => db, :settings => settings)
api         = EventWatcher.new(:browser => browser, :tracker => tracker, :logger => Logger.new("logs/#{@username}_#{Time.now}.log"))
api_events  = APIEvents.new(:tracker => tracker)
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
  # temp = api.poll_response

  # temp["people"].each do |user|
  #   unless @people_hash.has_key?(user["screenname"])
  #     @people_hash[user["screenname"]] = user
  #   end
  # end
  # begin
  #   temp["events"].each do |event|
  #     key = "#{event['server_gmt']}#{event['type']}"
  #     unless @hash[key] == event["server_seqid"]
  #       p "New #{event['type']} From #{event['from']}"
  #       p "At #{Time.at(event['server_gmt'])}"
  #       # p event['server_seqid']
  #       # p @people_hash[event['from']]
  #       @api.process(event, @people_hash[event['from'])
  #       # puts "-----------"
  #       @hash[key] = event["server_seqid"]
  #     end

  #   end
  # rescue
  #   puts "*****"
  #   p temp["events"]
  #   puts "*****"
  # end

  api.check_events

end