require './includes'

class Settings2

  attr_reader :verbose, :debug, :gender

  def initialize
    @verbose = false
    @debug = true
  end

end

class Query

  def initialize(login)
    @login = login
    settings = Settings2.new
    @db = DatabaseManager.new(:login_name => @login, :settings => settings)
  end

  def test_this
    @db.new_user_smart_query
  end

  def run
    test_this.each do |this|
      puts this["name"]
    end
  end


end

app = Query.new(ARGV[0])
app.run
