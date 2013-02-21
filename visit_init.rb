require './includes.rb'

@login = ARGV[0]
@csv_reader = DataReader.new(:username => @login)
@db = DatabaseManager.new(:login_name => @login)
@csv_reader.import
@db.import