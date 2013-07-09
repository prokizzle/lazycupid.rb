require './includes'

class Settings2

  attr_reader :verbose, :debug

  def initialize
    @verbose = false
    @debug = true
  end

end

class WhereIsSheFrom

    def initialize(login, user)
        @login = login
        @user = user
        settings = Settings2.new
        @db = DatabaseManager.new(:login_name => @login, :settings => settings)
    end

    def state
        @db.get_state(@user)
    end

    def run
        puts "#{@user}: #{state}"
    end

end

app = WhereIsSheFrom.new(ARGV[0], ARGV[1])
app.run

