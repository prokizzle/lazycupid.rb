require './includes'
@log          = Logger.new("logs/#{ARGV[0]}_#{Time.now}.log")


@browser = Session.new(:username => ARGV[0], :password => ARGV[1], :log => @log)
@browser.login
@browser.go_to("http://www.okcupid.com/visitors")

def raw
  @browser.current_user
end

def body
  @browser.body

end

def location_array(location)
  result    = location.scan(/,/)
  if result.size == 2
    city    = location.match(/(.+), (.+), (.+)/)[1]
    state   = location.match(/(.+), (.+), (.+)/)[2]
    country = location.match(/(.+), (.+), (.+)/)[3]
  elsif result.size == 1
    city    = location.match(/(.+), (.+)/)[1]
    state   = location.match(/(.+), (.+)/)[2]
  end
  {:city => city, :state => state}
end



def visitors
  @visitors = Array.new
  @final_visitors = Array.new

  @browser.go_to("http://www.okcupid.com/visitors")

  page = current_user.parser.xpath("//div[@id='main_column']/div").to_html
  users = page.scan(/.p.class=.user_name.>(.+)<\/p>/)
  users.each do |user|
    block = user.shift
    handle = block.match(/visitors.>(.+)<.a/)[1]
    aso = block.match(/aso.>(.+)<.p/)[1]
    age = aso.match(/(\d{2})/)[1].to_i
    gender = aso.match(/#{age} \/ (\w) \//)[1]
    sexuality = aso.match(/#{age} \/ #{gender} \/ (\w+) \//)[1]
    status = aso.match(/#{age} \/ #{gender} \/ #{sexuality} \/ ([\w\s]+)/)[1]
    location = block.match(/location.+>(.+)/)[1]
    city = location_array(location)[:city]
    state = location_array(location)[:state]
    @visitors.push({handle: handle, age: age, gender: gender, sexuality: sexuality, status: status, city: city, state: state})
  end


  until @visitors.size == 0
    user = @visitors.shift
    block = raw.parser.xpath("//div[@id='usr-#{user[:handle]}-info']/p[1]/script/text()
").text
    timestamp = block.match(/(\d+), .JOURNAL/)[1]
    addition = {timestamp: timestamp}
    final = user.merge(addition)
    @final_visitors.push(final)
    # puts block
  end
  @count = 0
  until @final_visitors.size == 0

    user = @final_visitors.shift
    @stored_timestamp = @database.get_visitor_timestamp(user[:handle]).to_i

    unless @stored_timestamp == user[:timestamp]
      @count += 1
      @database.add_user(user[:handle])
      @database.ignore_user unless user[:gender] == @settings.gender
      @database.set_gender(:username => user[:handle], :gender => user[:gender])
      @database.set_state(:username => user[:handle], :state => user[:state])

      increment_visitor_counter(user[:handle])
    end
    @database.set_visitor_timestamp(user[:handle], user[:timestamp])
  end
  @database.stats_add_visitors(@count.to_i)
end

visitors

# //div[@id="usr-#{user[:handle]}-info"]
# p page
