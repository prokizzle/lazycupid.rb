class Test
  def call_thing
    call_method
  end

  def call_method
    puts caller[0][/`.*'/].to_s.match(/`(.+)'/)[1]
  end

end

class Test2
  def intialize
    test = Test.new
  end

  def call_outside
    test.call_thing
  end
end

test = Test.new
test.call_thing
