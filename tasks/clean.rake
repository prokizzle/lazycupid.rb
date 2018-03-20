task :remove_unvisited do
  puts Match.where(account: "***REMOVED***", counts: 0).delete
end

task :reset_state_distance do
  account = ask("account: ")
  state = ask("state: ")
  distance = ask("distance: ")
  Match.where(account: account, state: state).exclude(city: "Austin").update(distance: distance)
end
