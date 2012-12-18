require_relative 'AutoRoller.rb'

class Roller
  attr_accessor :u
  attr_accessor :p
  attr_accessor :s

  def run
    @u = ARGV[0]
    @p = ARGV[1]
    @s = ARGV[2].to_i
    if !(defined? @s)
      @s = 400
    end
    app = AutoRoller.new()
    app.login(@u, @p)
    app.loadIgnoreList
    app.loadData
    app.run(@s)
  end

end

application = Roller.new
application.run