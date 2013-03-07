require 'rubygems'
require 'csv'
require 'progress_bar'

class DataReader
  attr_accessor :username, :data, :load, :zindex, :visit_count, :last_visit_date
  attr_reader :username, :data, :load, :zindex, :visit_count, :last_visit_date

  def initialize(args)
    @username = args[ :username]
    @db = DataWriter.new(@username.to_s + "_count.csv")
    @log = DataWriter.new(@username.to_s + ".csv")
    @names = Hash.new {|h, k| h[k] = 0 }
    @zindex = Hash.new {|h, k| h[k] = 0 }
    @visit_count = Hash.new {|h, k| h[k] = 0 }
    @last_visit_date = Hash.new {|h, k| h[k] = 0 }
    @ignore = Hash.new("false")
  end

  def create_new_user
    puts "Not found. Create new user? (y/n)"
    choice = gets.chomp
    if choice == "y"
      puts "Setting up new user"
      @db.new_file
      @log.new_file
    end
  end

  def is_valid_user
    # begin
    #   CSV.foreach(@username.to_s + "_count.csv", :headers => true, :skip_blanks => false) do |row|
    #     # print "."
    #   end
    #   true
    # rescue
    #   false
    # end
    File.exists?(@username.to_s + "_count.csv")
  end

  def import
    CSV.foreach(@username.to_s + ".csv", :headers => true, :skip_blanks => false) do |row|
      match_name = row[0]
      last_visit = row[3]
      @names[match_name] += 1
      @last_visit_date[match_name] = last_visit
    end
    self.convert_init
    self.save
  end

  def convert_init
    @names.each do |a, b|
      @ignore[a] = false
      @visit_count[a] = 0
      @zindex[a] = 1
    end
  end

  def load
    create_new_user unless (is_valid_user)
    begin
      # puts "Loading data file"
      CSV.foreach(@username.to_s + "_count.csv", :headers => true, :skip_blanks => false) do |row|
        text = row[0]
        count = row[1].to_i
        ignore = row[2]
        zindex = row[3].to_i
        visit_count = row[4].to_i
        last_visit = row[5].to_i
        @names[text] = count
        @ignore[text] = ignore
        @zindex[text] = zindex
        @visit_count[text] = visit_count
        @last_visit_date[text] = last_visit
      end
    rescue
    end
  end

  def save
    @bar = ProgressBar.new(@names.size)
    @db.clear
    @names.each do |a, b|
      c = @ignore[a].to_s
      d = @zindex[a].to_s
      e = @visit_count[a].to_s
      f = @last_visit_date[a]
      row = [a, b, c, d, e, f]
      @db.data = row
      @db.append(row) # if (a.length > 0)
      @bar.increment!
    end
  end


  def log(match_name, match_percent=0)
    row = [match_name.to_s,match_percent.to_s, Time.now, Time.now.to_i]
    @log.data = row
    @log.append
    @names[match_name] = (@names[match_name] + 1)
    @last_visit_date[match_name] = Time.now.to_i
  end

  def data
    @names
  end

  def add_new_match(user)
    unless (@names.has_key?(user))
      @names[user] = 0
    end
  end

  def remove_match(user)
    if @names.has_key?(user)
      puts "Removing #{user}"
      # @names.tap { |hs| hs.delete(user) }
      @names.delete(user)
    end
  end

  def ignore
    @ignore
  end

  def datas(u, num)
    @names[u] = num
  end

  def run
    import
  end


end

class CSVWriter
  attr_accessor :mode, :data
  attr_reader :mode, :data

  def write(file, mode, data)
    CSV.open(file, mode) do |csv|
      csv << data
    end
  end

end


class DataWriter

  attr_accessor :file, :data
  attr_reader :file, :data

  def initialize(file="output.csv")
    @data = Array.new
    @file = file
    @writer = CSVWriter.new

  end

  def append(row=@data)
    @writer.write(@file, "ab", @data)
  end

  def clear
    # @writer.write(@file, "wb", [])
    File.open(@file, 'w') {|f|  }
  end

  def new_file
    clear
  end

  def write(file, mode, data)
    @doc = CSV.open(file, mode) do |csv|
      csv << data
    end
    @doc.close
  end

end

# application = DataManager.new ARGV[0]

# application.run
