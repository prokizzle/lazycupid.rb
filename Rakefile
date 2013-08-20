namespace :db do
  task :migrate do
    result = %x{sequel -m db/migrations/ -E postgres://localhost/lazy_cupid}
    puts result
  end

  task :create do
  	result = %x{createdb lazy_cupid}
  end
end
