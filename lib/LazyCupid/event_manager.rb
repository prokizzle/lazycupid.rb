module LazyCupid
  class EventManager
    attr_reader :quit, :status, :can_scrape
    attr_accessor :quit, :status, :can_scrape

    def initialize
      @quit               = false
      @status             = 1
      @can_scrape         = true
      @events             = Hash.new(0)
    end

    def current_time
      Time.now.to_i
    end

    def quit
      @quit
    end

    def quit_time
      quit = action_time_is_ready("quit")
    end

    def quit_now
      schedule_task("quit", current_time)
    end


    def status
      @status
    end

    def can_scrape
      @can_scrape
    end

    def schedule_task(key, time_string)
      @events[key] = Chronic.parse(time_string).to_i
    end

    def scheduled_action_time(key)
      @events[key].to_i
    end

    def action_time_is_ready(key)
      scheduled_action_time(key) >= current_time
    end

  end
end
