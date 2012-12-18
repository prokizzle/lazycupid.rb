#!/usr/bin/env ruby
require_relative 'AutoRoller.rb'

class Roller
attr_accessor :username
attr_accessor :password

@username = "danceyrselfcln"
@password = "123457"

  def run
    @number = ARGV[0].to_i
    app = AutoRoller.new()
    app.clear
    app.login(@username, @password)
    app.smartRoll(@number)
  end
end

application = Roller.new
application.username = "danceyrselfcln"
application.password = "123457"
application.run

