

class BlockList

  def initialize(database)
    @database = database
    @counts = @database.data
  end

  def add(user)
    if @counts[user].to_i < 1 ||
        @database.ignore[user] = true
    end
  end

  def ignoreUser(match)
    @ignore[match] = true
  end

  def loadIgnoreList
    begin
      @ignore = Hash.new(0)
      CSV.foreach(@username + "_ignore.csv", :headers => true, :skip_blanks => false) do |row|
        text = row[0]
        @ignore[text] = true
      end
    rescue
      ignoreUser(@username)
    end

  end

  def checkIgnore? (user)
    (@ignore[user] == true)
  end

end
