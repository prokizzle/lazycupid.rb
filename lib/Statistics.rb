class Statistics
  attr_reader :visitors, :start_time, :visited, :autodiscover_on
  attr_accessor :visitors, :start_time, :visited, :autodiscover_on

  def initialize

  end

  def visitors
    @visitors
  end

  def visited
    @visited
  end

  def start_time
    @start_time
  end

end
