class DatabaseWriter
  # def toDatabase
  #   CSV.foreach(@username + ".csv", :headers => true) do |row|
  #     DartaBase.create!(row.to_hash)
  #   end
  # end
  #
  def init
    @db = Sequel.connect('sqlite://matches.db')
  end

  def create_tables
      @db.create_table :matches do
        primary_key :id
        String :user
        Integer :count
      end
  end



    # matches = @db[:matches]
  end

  def printDB
    matches = @db[:matches]
    matches.each{|row| puts row}
  end

  def getUserId(user)
    return ids[user]
  end

  def setUserIds
    @ids = Hash.new(0)
    matches = @db[:matches]
    matches.each do |hash|
      hash.each do |a,b|
        if a == 'user'
          @ids[a]=b.to_s
        end
      end
    end
    @ids.each do|a,b|
      puts a.to_s + ":" + b.to_s
    end
  end

  def getCounts(match)
    return @names[match]
  end
end