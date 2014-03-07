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

##Requirements

+ Postgres: db name lazy_cupid
+ Ruby

##Installation:

	createdb lazy_cupid
    bundle install

On first run, after successful login, LzC automatically creates config files in `config/` with default values. Make changes to database.yml to reflect your postgres configuration, and also `_your_user_name_.yml `for your match preferences. You will need to restart LazyCupid for changes in config to take effect.

##Migrations

Apply database changes before running on every git pull with *Sequel Migrations* tool:
`sequel -m db/migrations/ -E postgres://localhost/lazy_cupid`

or

`rake db:migrate`

##Usage:

`ruby bin/lazycupid`

or

`ruby bin/lazycupid [username] [password]`


##Todo:

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

