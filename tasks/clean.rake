task :remove_unvisited do
  puts Match.where(account: "***REMOVED***", counts: 0).delete
end