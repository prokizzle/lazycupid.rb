#Ruby LazyCupid
_An intelligent auto-visitor bot for OKCupid._

+ Finds new matches from the match search
+ Checks your inbox and tracks message senders
+ Visits matches on an adjustable schedule
+ Accepts config options for match qualities and distance
+ Auto-blocks hidden users and previous message senders
+ Stores user profile information in a PostgreSQL database
+ Uses private OKCupid API
+ Multi-threaded (via rufus-scheduler)

###Requirements

+ Postgres: db name lazy_cupid
+ Ruby

####Installation:

    bundle install


##Usage:

    ruby bin/lazycupid

or

    ruby bin/lazycupid _username_ _password_


####Todo:

+ Alter database schema to mutli tables
+ Switch to ActiveRecord database format (Sequel gem)
+ Share stored user details among all tenants
+ Parse individual message threads
+ Minimize API usage
+ Improve visitors page parser
+ Store links or file records for user profile thumbnails
+ Create Rails app
  + visualizing patterns, data
  + success rates
  + average message response times
  + advice on improving responses
  + overall statistics
  + weekly, daily reports