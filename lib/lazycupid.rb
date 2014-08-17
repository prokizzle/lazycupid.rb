require_relative 'LazyCupid/runner'

module LazyCupid

  # Dotenv.load

  Dir[File.dirname(__FILE__) + '/LazyCupid/*.rb'].each do |file|
    require file
  end

end