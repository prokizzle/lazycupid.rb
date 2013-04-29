require './includes'

class Settings2
attr_reader :verbose, :debug
end

@config = Settings2.new
@username = '***REMOVED***'


@db = DatabaseManager.new(:login_name => @username, :settings => @config)

result = @db.test_this
p result
puts result

result.each do |item|
  p item
  puts item
end
