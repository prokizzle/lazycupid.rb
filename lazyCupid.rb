 require_relative 'AutoRoller.rb'

  # begin
  @u = ARGV[0]
  @p = ARGV[1]
  @s = ARGV[2].to_i
  lazyCupid = AutoVisitor.new()
  # lazyCupid.initialize(@u,@p,@s)
  # @s = ARGV[3].to_i
  puts "Initializing..."
  lazyCupid.login(@u, @p)
  lazyCupid.importCSV(@u)
  # lazyCupid.ignoreUser "james"
  lazyCupid.loadIgnoreList
  lazyCupid.loadData
  lazyCupid.run(@s)
  # lazyCupid.lastVisited()
  lazyCupid.smartRoll(2)
  # lazyCupid.stalk()
  # lazyCupid.saveData(@names)
# rescue
  puts "An error occurred in runner"
# end
  # singleVisits