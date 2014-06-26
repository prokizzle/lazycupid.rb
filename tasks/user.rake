namespace :match do
  task :delete do
   puts Match.where(account: "***REMOVED***", name: ask("Username: ")).delete
 end
end