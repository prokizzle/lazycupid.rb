require './includes'

@log          = Logger.new("logs/#{ARGV[0]}_#{Time.now}.log")

@hash = Hash.new { |hash, key| hash[key] =  0}
browser = Session.new(:username => ARGV[0], :password => ARGV[1], :log => @log)
app = EventWatcher.new(:browser => browser)
puts "Logging in..."
app.login
@last_event_time = 0

def msg_notify
  unless @event["server_gmt"].to_i == @last_event_time
    puts "New message from #{@event["screenname"]}" #unless @event["server_gmt"] == @gmt
  end
  @last_event_time = @event["server_gmt"].to_i
end

def stalk
  unless @event["server_gmt"].to_i == @last_event_time
    puts "New visit from #{@event['screenname']}"
  end
  @last_event_time = @event["server_gmt"].to_i
end

begin
  loop do
    # if app.check_events.respond_to?('each')

    puts "Requesting..."
    temp = app.poll_response
    puts "Reponse received."
    count = 0
    unless temp == nil
      # temp.each do |hash|
      temp["events"].each do |event|
        if event.has_key?('from')
          @index = count
        end
        count += 1
      end
      if @index && temp["events"][@index]
        @event = temp["events"][@index]
        @details = temp["people"]
        @event = @event.merge(@details[@details.size - 1])
        temp = @event["type"]
        # puts temp.to_s
        self.send(temp)
      end
    end
    sleep 2
  end
rescue Interrupt, SystemExit
  app.logout
end
