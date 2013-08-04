require 'sequel'
DB = Sequel.connect('sqlite://blog.db')
# DB.drop_table :matches

#Match table: account specific information on each visited or queued user
class Match < Sequel::Model
  many_to_one :handle
  many_to_one :user
  set_primary_key [:handle, :login]
end

#User table: a collection of all okcupid users with detailed scraped information
# PK: handle (their username)
class User < Sequel::Model

end

#Accounts table: all accounts that can login to lazycupid
# PK: account_name
class Account < Sequel::Model
end

#Messages table: each scraped message gets stored here
#PK: message_id (an integer created by OKCupid)
class Message < Sequel::Model
end

#IncomingVisits table: every time someone visits you, store time and username
#PK: Visit time integer
class IncomingVisit < Sequel::Model
end

#OutgoingVisits table: every user you visit, store a log here
class OutgoingVisit < Sequel::Model
end

User.create(handle: '***REMOVED***')
record = Match.create(:login => '***REMOVED***')
record.handle = User[:handle => '***REMOVED***']
puts record.handle
