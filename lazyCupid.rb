 require_relative 'AutoRoller.rb'

  lazyCupid = AutoVisitor.new()

  @u = ARGV[0]
  @p = ARGV[1]
  @m = ARGV[2].to_i
  @s = ARGV[3].to_i
  puts "Initializing..."
  lazyCupid.login(@u, @p)
  # lazyCupid.importCSV(@u)
  # lazyCupid.ignoreUser "kimmybeth"
  lazyCupid.loadIgnoreList
  lazyCupid.loadData
  # lazyCupid.run(@m, @s)
  # lazyCupid.lastVisited()
  lazyCupid.smartRoll(3)
  # lazyCupid.stalk()
  lazyCupid.saveData(@names)

  # singleVisits
  puts ""
  puts "Done."
  puts "---"