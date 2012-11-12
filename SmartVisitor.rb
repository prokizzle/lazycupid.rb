require_relative 'AutoRoller.rb'
require_relative 'OutputScrape.rb'

def SmartVisitor < AutoRoller

def smartRoll(number)
    begin
      puts "Smart Roll."
      link_queue = Array.new(0)
      visit_queue = Array.new(0)
      CSV.foreach(@username + "_count.csv", :headers => true, :skip_blanks => false) do |row|
        text = row[0]
        count = row[1].to_i
        if count == number
          visit_queue += [text]
        end
      end


      visit_queue.each do |user|
        puts "Visting: " + user
        roll = @agent.get("http://www.okcupid.com/profile/#{user}/")
        @names[user] += 1
        sleep 10
      end
    rescue SystemExit, Interrupt
      puts "","User quit. Saving data..."
      saveData(@names)
      puts "Done."
    end
  end

  def stalk(user, times)
    puts "Stalk Mode","-------------","User: " + user.to_s

    i=1
    # until (i==times.to_i)
    30.times do
      roll = @agent.get("http://www.okcupid.com/profile/#{user}/")
      @names[user] += 1
      sleep 30000
    end
  end
end