class Application

  def initialize
    @array = Array.new
    @array = reload
  end

  def reload
    [1, 2, 3, 4, 5, 6, 7]
  end

  def cache
    if @array.size == 0
      @array = reload
    else
      @array
    end
  end

  def next_item
    cache.shift
  end

end

app = Application.new

20.times do
  puts app.next_item
  sleep 2
end
