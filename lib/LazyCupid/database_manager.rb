require 'uuidtools'
require 'pg'
require 'progress_bar'
require 'sequel'

module LazyCupid
$db = Sequel.postgres(
        :host =>      'localhost',
        :database =>  $db_name,
        :user =>      $db_user,
        :database =>  'lazy_cupid',
      )
#   class User < Sequel::Model
#     set_primary_key [:name]
#   end

  # A Postgres database SQL wrapper for reading and writing data to and from
  # the database.
  #
  # @param login_name [Symbol] [account name for your okcupid account]
  # @param settings [Symbol] settings object
  # @param tasks [Symbol] Boolean value for whether or not to run db tasks
  # on initialization
  #
  class DatabaseMgr
    attr_reader :login, :debug, :verbose


    def initialize(args)
      @did_migrate = false
      @login    = args[:login_name]
      @settings = args[:settings]
      @db = $db
      @db = PGconn.connect( :dbname => @settings.db_name,
                            :password => @settings.db_pass,
                            :user => @settings.db_user,
                            :host => @settings.db_host
                            )
      # tasks     = args[:tasks] unless @settings.debug
      #db_tasks #if args[:tasks]
      @verbose  = @settings.verbose
      @debug    = @settings.debug
      $sequel = Sequel.postgres(
        :host =>      @settings.db_host,
        :database =>  @settings.db_name,
        :user =>      @settings.db_user,
        :password =>  @settings.db_pass
      )
# @sequel = Sequel.connect("#{@settings.db_adapter}://#{@settings.db_user}:#{@settings.db_pass}@#{@settings.db_host}/#{@settings.db_name}")
      # @users            = @sequel[:users]
    end

    def db
      @db
    end

    def verbose
      @verbose
    end

    def delete_self_refs
      @db.exec("delete from matches where name = $1", [@login])
      @db.exec("delete from matches where name = $1", [nil])
      @db.exec("delete from matches where name = $1", [""])
    end

    def db_tasks
      # import
      puts "Executing db tasks..."
      delete_self_refs
      # @db.exec("delete from matches where distance > $1 and ignore_list=0 and account=$2", [@settings.max_distance, @login])
      # @db.exec("update matches set ignore_list=1 where sexuality=$1 and account=$2", ["Gay", @login]) unless @settings.visit_gay
      # @db.exec("update matches set ignore_list=1 where sexuality=$1 and account=$2", ["Straight", @login]) unless @settings.visit_straight
      # @db.exec("update matches set ignored=true where ignore_list=1")
      # @db.exec("update matches set ignore_list=1 where sexuality=$1 and account=$2", ["Bisexual", @login]) unless @settings.visit_bisexual
      # @db.exec("update matches set ignored=false where account=$1 and ignored=true", [@login])
      fix_blank_distance
    end

    def action(stmt)
      db.transaction
      stmt.execute
      db.commit
    end

    def open
      open_db
    end

    def guess_distance(account, city, state)
      result = @db.exec("select distance from matches where account=$1 and city=$2 and state=$3 and distance is not null limit 1", [account, city, state])
      alt = @db.exec("select distance from matches where account=$1 and state=$2 and distance is not null limit 1", [account, state])
      begin
        return result[0]["distance"]
      rescue
        return alt[0]["distance"] rescue nil
      end


    end

    def fix_blank_distance
      list = @db.exec("select city, state, account, added_from from matches where distance is null and city is not null and state is not null")
      queue = []
      a_from = Hash.new
      list.to_a.each do |r|
        queue << r
        a_from[r["added_from"]] += 1 rescue a_from[r["added_from"]] = 1
      end
      puts a_from
      bar = ProgressBar.new(queue.to_set.to_a.size)
      c = 0
      queue.to_set.to_a.each do |r|
        # puts "Updating #{r["city"]}"
        @db.exec("update matches set distance=$1 where account=$2 and city=$3 and state=$4 and distance is null", [guess_distance(r["account"], r["city"], r["state"]), r["account"], r["city"], r["state"]])
        bar.increment!
        c += 1
        # break if c >= 50
      end
    end

    def add_message(args)
      user = args[:username]
      message_id = args[:message_id]
      timestamp = args[:timestamp]

      # @db.exec("insert into incoming_messages(account, username, message_id, timestamp) values($1, $2, $3, $4)", [@login, user, message_id, timestamp])
      # begin
      IncomingMessage.find_or_create(message_id: message_id) do |m|
        m.account = @login
        m.timestamp = timestamp
        m.username = user
      end
    # rescue Sequel::DatabaseError => e
      # puts e.sql
      # sleep 10000
    # end
    end

    def set_estimated_distance(user, city, state)
      unless @db.exec("select * from matches where name=$1 and account=$2 and distance >= 0", [user, @login]).to_a.empty?
        @db.exec("update matches set distance=$1 where name=$2 and account=$3", [guess_distance(@login, city, state), user, @login])
      end
    end

    def set_location(args)
      user = args[:user]
      city = args[:city]
      state = args[:state]
      distance = guess_distance(@login, city, state)
      @db.exec("update matches set distance=$1, city=$2, state=$3 where name=$4 and account=$5", [distance, city, state, user, @login])
    end

    def stats_add_visit(name)
      @db.exec("update stats set total_visits=total_visits + 1 where account=$1", [@login])
      @db.exec("insert into outgoing_visits(name, account, timestamp) values($1,$2,$3)", [name, @login, Time.now.to_i])
    end

    def stats_add_visitor
      @db.exec("update stats set total_visitors=total_visitors+1 where account=$1", [@login])
    end

    def stats_add_new_user
      # updated = stats_get_new_users_count + 1
      @db.exec("update stats set new_users=new_users + 1 where account=$1", [@login])
    end

    def stats_add_new_message
      @db.exec("update stats set total_messages=total_messages + 1 where account=$1", [@login])
    end

    def stats_get_visitor_count
      result = @db.exec("select total_visitors from stats where account=$1", [@login])
      result[0]["total_visitors"].to_i
    end

    def stats_get_visits_count
      result = @db.exec("select total_visits from stats where account=$1", [@login])
      result[0]["total_visits"].to_i
    end

    def stats_get_new_users_count
      result = @db.exec("select new_users from stats where account=$1", [@login])
      result[0]["new_users"].to_i
    end

    def stats_get_total_messages
      result = @db.exec("select total_messages from stats where account=$1", [@login])
      result[0]["total_messages"].to_i
    end

    def add_user(user)
      # unless existsCheck(username) || username == "pictures"
      #   puts "Adding user:        #{username}" if $verbose
      #   # @db.transaction
      #   @db.exec("insert into matches(name, ignore_list, time_added, account, counts, gender, added_from) values ($1, $2, $3, $4, $5, $6, $7)", [username.to_s, 0, Time.now.to_i, @login.to_s, 0, gender, added_from])
      #   # @db.commit
      #   # stats_add_new_user
      # else
      #   @db.exec("update matches set inactive=false where name=$1", [username])
      #   puts "User already in db: #{username}" if $verbose
      # end'
      puts "Adding:\t\t#{user[:username]}" if $verbose
      distance = guess_distance(@login, user[:city], user[:state]) if user[:city]

      Match.find_or_create(:name => user[:username], :account => @login) do |u|
        u.gender = user[:gender]
        u.age = user[:age] if user[:age]
        u.city = user[:city] if user[:city]
        u.state = user[:state] if user[:state]
        u.distance = distance if distance
        u.added_from ||= user[:added_from]
        u.inactive = false
        u.ignored = user[:ignored] if user[:ignored]
      end
    end

    def add(user)

      # unless existsCheck(user[:username]) || user[:username] == "pictures"
        puts "Adding user:        #{user[:username]}" if $verbose

        distance = guess_distance(@login, user[:city], user[:state]) unless user[:distance]

      #   @db.exec("insert into matches(name, ignore_list, time_added, account, counts, gender, added_from, city, state, distance, match_percent, age) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)", [user[:username], 0, Time.now.to_i, @login.to_s, 0, user[:gender], user[:added_from], user[:city], user[:state], distance, user[:match_percent], user[:age]])
      # else
      #   @db.exec("update matches set inactive=false where name=$1", [user[:username]])
      #   puts "User already in db: #{user[:username]}" if $verbose
      # end

      Match.find_or_create(:name => user[:username], :account => @login) do |u|
        u.age = user[:age]
        u.match_percent = user[:match_percent]
        u.distance = distance || user[:distance]
        u.time_added ||= Time.now.to_i
        u.gender = user[:gender]
        u.added_from ||= user[:added_from]
        u.city = user[:city]
        u.state = user[:state]
        u.inactive = false
      end

    end

    def delete_user(username)
      puts "Deleting #{username}"
      # @db.exec("delete from matches where name=$1 and account=$2", [username, @login])
    end

    def get_user_info(username)
      @db.exec("select * from matches where name=$1 and account=$2", [username, @login])
    end

    def get_match_names
      @db.exec( "select name from matches where account=$1", [@login] )
    end

    def all_ignore_list
      @db.exec("select name from matches where ignore_list=1")
    end

    def get_visit_count(user)
      row = @db.exec( "select counts from matches where name=$1 and account=$2", [user, @login])
      begin
        row[0]["counts"].to_i
      rescue
        0
      end
    end

    def set_visit_count(name, count)
      @db.exec("update matches set counts = $1 where name=$2 and account = $3", [count, name, @login])
    end

    # def get_last_visit_date(user)
    #   result = @db.exec( "select last_visit from matches where name=$1 and account=$2", [user, @login])
    #   result[0]["last_visit"].to_i
    # end

    def update_visit_count(match_name, number)
      puts "Updating visit count: #{match_name}" if $verbose
      @db.exec( "update matches set counts=$1 where name=$2 and account=$3", [number.to_i, match_name, @login] )
    end

    def increment_visit_count(match_name)
      puts "Incrementing visit count: #{match_name}" if $verbose
      @db.exec("update matches set counts=counts + 1 where name=$1 and account=$2", [match_name, @login])
    end

    def rename_alist_user(old_name, new_name)
      @db.exec("update matches set name=$1 where name=$2", [new_name, old_name])
      UsernameChange.find_or_create(:old_name => old_name) do |u|
        u.new_name = new_name
      end
    end

    def followup_query
      # [todo] - add support for readability score filtering

      puts "**********", "Current distance: #{$max_distance}", "**********" if $debug

      min_time            = Chronic.parse("#{@settings.days_ago.to_i} days ago").to_i
      desired_gender      = $gender
      alt_gender          = $alt_gender
      min_age             = @settings.min_age
      max_age             = @settings.max_age
      age_sort            = @settings.age_sort
      height_sort         = @settings.height_sort
      last_online_cutoff  = @settings.last_online_cutoff
      max_counts          = @settings.max_followup
      min_percent         = $min_percent
      distance            = $max_distance

      if @settings.visit_gay
        visit_gay = "Gay"
      else
        visit_gay = "Null"
      end

      if @settings.visit_bisexual
        visit_bisexual = "Bisexual"
      else
        visit_bisexual = "Null"
      end

      if @settings.visit_straight
        visit_straight = "Straight"
      else
        visit_straight = "Null"
      end

      # if bisexual-m
      #   (sexuality="Bisexual" && gender="F")
      #   or (sexuality="Bisexual" && gender="M")
      #   or (sexuality="Gay" && gender="M")
      #   or (sexuality="Straight" && gender="F")
      # end
      # if bisexual-f
      #   (sexuality="Bisexual" && gender="M")
      #   or (sexuality="Bisexual" && gender="F")
      #   or (sexuality="Gay" && gender="F")
      #   or (sexuality="Straight" && gender="M")
      # end

      result          = @db.exec("
        select * from matches
        where account=$8
        and (last_visit <= $1 or last_visit is null)
         and (counts <=$2 or counts is null)
         and (distance <= $3 or distance is null)
         and (ignored = false or ignored is null)
         and (inactive = false or inactive is null)
         and (age between $4 and $5 or age is null)
         and (match_percent between $6 and 100 or match_percent is null or match_percent=0)
         and (gender=$7 or gender=$12)
         and (sexuality=$9 or sexuality=$10 or sexuality=$11 or sexuality is null)
         and (last_online > extract(epoch from (now() - interval '#{last_online_cutoff} days')) or last_online is null)
        order by distance ASC, counts ASC, sexuality DESC, last_online DESC, match_percent DESC, height #{height_sort}, age #{age_sort}
        limit 20", [
                                   min_time.to_i, #1
                                   max_counts, #2
                                   distance, #3
                                   min_age, #4
                                   max_age, #5
                                   min_percent, #6
                                   desired_gender, #7
                                   @login, #8
                                   visit_gay, #9
                                   visit_straight, #10
                                   visit_bisexual, #11
      alt_gender]) #12

      # result = Match.where(
      #   account => @login,
      #   last_visit <=
      #   )

      # result = Match.where("account=?
        # and (last_visit <= ? or last_visit is null)
         # and (counts <= ? or counts is null)
         # and (distance <= ? or distance is null)
         # and (ignored = false or ignored is null)
         # and (inactive = false or inactive is null)
         # and (age between ? and ? or age is null)
         # and (match_percent between ? and 100 or match_percent is null or match_percent=0)
         # and (gender=? or gender=?)
         # and (sexuality=? or sexuality=? or sexuality=? or sexuality is null)
         # and (last_online > extract(epoch from (now() - interval '#{last_online_cutoff} days')) or last_online is null)
        # ",
                                   # @login, #8
                                  # min_time.to_i, #1
                                   # max_counts, #2
                                   # distance, #3
                                   # min_age, #4
                                   # max_age, #5
                                   # min_percent, #6
                                   # desired_gender, #7
                                  # alt_gender,
                                   # visit_gay, #9
                                   # visit_straight, #10
                                   # visit_bisexual #11
      # ).to_hash(:name) #12
# order by counts ASC, last_online DESC, distance ASC, match_percent DESC, height #{height_sort}, age #{age_sort}
#         limit 20"
      return result
    end

    def user_record_exists(user)
      @db.exec( "select exists(select * from matches where name=$1 and account=$2", [user, @login] )
    end

    def set_match_percentage(user, match_percentage)
      # begin
      @db.exec("update matches set match_percent=$1 where name=$2 and account=$3", [match_percentage, user, @login])
      # rescue
      #   @db.exec("alter table matches add column match_percent text")
      #   @db.exec("update matches set match_percent=$1 where name=$2", [match_percentage, user])
      # end

    end

    def set_friend_percentage(user, percent)
      @db.exec("update matches set friend_percent=$1 where name=$2 and account=$3", [percent, user, @login])
    end

    def get_friend_percentage(user)
      @db.exec("select friend_percent from matches where name=$1 and account=$2", [user, @login])
    end

    def set_enemy_percentage(user, percent)
      @db.exec("update matches set friend_percentage=$1 where name=$2 and account=$3", [percent, user, @login])
    end

    def get_enemy_percentage(user)
      @db.exec("select enemy_percent from matches where name=$1 and account=$2", [user, @login])
    end

    def set_slut_test_results(user, value)
      @db.exec("update matches set slut_test_results=$1 where name=$2 and account=$3", [value, user, @login])
    end

    def get_slut_test_results(user)
      @db.exec("select slut_test_results from matches where name=$1 and account=$2", [user, @login])
    end

    def set_ethnicity(user, value)
      @db.exec("update matches set ethnicity=$1 where name=$2 and account=$3", [value, user, @login])
    end

    def get_ethnicity(user)
      @db.exec("select ethnicity from matches where name=$1 and account=$2", [user, @login])
    end

    def set_height(user, value)
      @db.exec("update matches set height=$1 where name=$2 and account=$3", [value, user, @login])
    end

    def get_height(user)
      @db.exec("select height from matches where name=$1 and account=$2", [user, @login])
    end

    def set_body_type(user, value)
      @db.exec("update matches set body_type=$1 where name=$2 and account=$3", [value, user, @login])
    end

    def get_body_type(user)
      @db.exec("select body_type from matches where name=$1 and account=$2", [user, @login])
    end

    def set_smoking(user, value)
      @db.exec("update matches set smoking=$1 where name=$2 and account=$3", [value, user, @login])
    end

    def get_smoking(user)
      @db.exec("select smoking from matches where name=$1 and account=$2", [user, @login])
    end

    def set_drinking(user, value)
      @db.exec("update matches set drinking=$1 where name=$2 and account=$3", [value, user, @login])
    end

    def get_drinking(user)
      @db.exec("select drinking from matches where name=$1 and account=$2", [user, @login])
    end

    def set_drugs(user, value)
      @db.exec("update matches set drugs=$1 where name=$2 and account=$3", [value, user, @login])
    end

    def get_drugs(user)
      @db.exec("select drugs from matches where name=$1 and account=$3", [user, @login])
    end

    def set_kids(user, value)
      @db.exec("update matches set kids=$1 where name=$2 and account=$3", [value, user, @login])
    end

    def get_kids(user)
      @db.exec("select kids from matches where name=$1 and account=$2", [user, @login])
    end

    def set_last_online(user, date)
      @db.exec("update matches set last_online=$1 where name=$2 and account=$3", [date, user, @login])
    end

    def get_last_online(user)
      result = @db.exec("select last_online from matches where name=$1 and account=$2", [user, @login])
      result[0]["last_online"].to_i
    end

    def set_distance(args)
      user = args[ :username]
      dist = args[ :distance]
      @db.exec("update matches set distance=$1 where name=$2 and account=$3", [dist, user, @login])
    end

    def get_distance(args)
      user = args[ :username]
      @db.exec("select distance from matches where name=$1 and account=$2", [user, @login])
    end

    def set_state(args)
      user = args[ :username]
      state = args[ :state]
      @db.exec("update matches set state=$1 where name=$2 and account=$3", [state, user, @login])
    end

    def get_state(user)
      result = @db.exec("select state from matches where name=$1 and account=$2", [user, @login])
      result[0]["state"].to_s
    end

    def set_age(user, age)
      @db.exec("update matches set age=$1 where name=$2 and account=$3", [age.to_i, user, @login])
    end

    def get_age(user)
      result = @db.exec("select age from matches where name=$1 and account=$2", [user, @login])
      result[0]["age"].to_i
    end

    def set_time_added(args)
      user = args[ :username]
      @db.exec("update matches set time_added=$1 where name=$2 and account=$3", [Time.now.to_i, user, @login])
    end

    def set_city(user, city)
      @db.exec("update matches set city=$1 where name=$2 and account=$3", [city, user, @login])
    end

    def get_city(user)
      result = @db.exec("select city from matches where name=$1 and account=$2", [user, @login])
      result[0]["city"].to_s
    end

    def set_gender(args)
      user = args[ :username]
      gender = args[ :gender]
      @db.exec("update matches set gender=$1 where name=$2 and account=$3", [gender, user, @login])
    end

    def get_gender(user)
      @db.exec("select gender from matches where name=$1 and account=$2", [user, @login])
    end

    def set_sexuality(user, sexuality)
      @db.exec("update matches set sexuality=$1 where name=$2 and account=$3", [sexuality, user, @login])
    end

    def get_sexuality(user)
      @db.exec("select sexuality from matches where name=$1 and account=$2", [user, @login])
    end

    def get_match_percentage(user)
      result = @db.exec("select match_percent from matches where name=$1 and account=$2", [user, @login])
      result[0]["match_percent"].to_i
    end

    def increment_visitor_counter(visitor)
      @db.exec( "update matches set visit_count=visit_count+1 where name=$1 and account=$2", [visitor, @login])
    end

    def increment_received_messages_count(user)
      puts "Recieved msg count updated: #{user}" if $verbose
      @db.exec("update matches set r_msg_count=r_msg_count+1 where name=$1 and account=$2", [user, @login])
    end

    def get_received_messages_count(user)
      result = @db.exec("select r_msg_count from matches where name=$1 and account=$2", [user, @login])
      result[0]["r_msg_count"].to_i
    end

    def set_last_received_message_date(user, date)
      puts "Last Msg date updated: #{user}:#{date}" if $verbose
      @db.exec("update matches set last_msg_time=$1 where name=$2 and account=$3", [date.to_i, user, @login])
    end

    def get_last_received_message_date(user)
      result = @db.exec("select last_msg_time from matches where name=$1 and account=$2", [user, @login])
      begin
        result.first["last_msg_time"].to_i
      rescue
        # puts e.message
        # puts e.backtrace
        # sleep 10
        0
      end
    end

    def get_visitor_count(visitor)
      result = @db.exec( "select visit_count from matches where name=$1 and account=$2", [visitor, @login])
      begin
        result[0]["visit_count"].to_i
      rescue
        0
      end
    end

    def get_my_last_visit_date(user)
      result = @db.exec("select last_visit from matches where name=$1 and account=$2", [user, @login])
      # begin
      result[0]["last_visit"].to_i
      # rescue
      #   0
      # end
    end

    def get_prev_visit(user)
      result = @db.exec("select prev_visit from matches where account=$1 and name=$2", [@login, user])
      begin
        result[0]["prev_visit"].to_i
      rescue
        0
      end
    end


    def set_my_last_visit_date(user, date=Time.now.to_i)
      prev = get_my_last_visit_date(user)
      now = Time.now.to_i
      puts "Last visit: #{prev}" if $debug
      puts "Now: #{now}" if $debug
      @db.exec("update matches set prev_visit=$1 where name=$2 and account=$3", [get_my_last_visit_date(user), user, @login])
      @db.exec( "update matches set last_visit=$1 where name=$2 and account=$3", [Time.now.to_i, user, @login])
    end

    def set_visitor_timestamp(visitor, timestamp)
      puts "Updating last visit time: #{visitor}" if $verbose
      @db.exec( "update matches set visitor_timestamp=$1 where name=$2 and account=$3", [timestamp, visitor, @login])
    end

    def get_visitor_timestamp(visitor)
      if existsCheck(visitor)
        result = @db.exec("select visitor_timestamp from matches where name=$1 and account=$2", [visitor, @login])
        result[0]["visitor_timestamp"].to_i
      else
        @db.exec("insert into matches(name, counts, visitor_timestamp, ignore_list, account, added_from) values ($1, $2, $3, $4, $5, $6)", [visitor, 0, Time.now.to_i, 0, @login, "visitors"])
        set_visitor_timestamp(visitor, Time.now.to_i)
        Time.now.to_i
      end
    end

    def get_total_received_message_count
      result = @db.exec("select count(name) from matches where r_msg_count is not null and account=$1", [@login])
      result[0][0].to_i
    end

    def get_all_message_senders
      @db.exec("select name, city, state from matches where r_msg_count is not null and account=$1", [@login])
    end

    def log2(user)
      # p user[:handle]
      # p user
      if user[:handle]
        unless existsCheck(user[:handle])
          add_user(user[:handle], user[:gender], "unknown")
        end

        increment_visit_count(user[:handle])
        set_my_last_visit_date(user[:handle])
        set_user_details(user)
        p "Height: #{user[:height]}" if $debug
      end
      stats_add_visit(user[:handle])
    end

    def set_user_details(user)
      @db.exec("update matches
      set (gender, sexuality, match_percentage, state, distance, age, city, height, last_online, last_visit, friend_percent, enemy_percent) =
      ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
      where name=$13",
               [user[:gender],
                user[:sexuality],
                user[:match_percentage],
                user[:state],
                user[:distance],
                user[:age],
                user[:city],
                user[:height],
                user[:last_online],
                Time.now.to_i,
                user[:friend_percentage],
                user[:enemy_percentage],
                user[:handle]])

      User.find_or_create(:name => user[:handle]) do |u|
                        u.age =  user[:age]
                        u.gender =  user[:gender]
                        u.sexuality =  user[:sexuality]
                        # u.relationship_status =  user[:relationship_status]
                        u.city =  user[:city]
                        u.state =  user[:state]
                        u.height =  user[:height]
                        u.last_online =  user[:last_online]
                        u.smokes =  (user[:smoking] != "No")
                        u.drinks =  (user[:drinking] != "Not at all")
                        u.bodytype = user[:bodytype]
                        u.ethnicity = user[:ethnicity]
                        u.drugs =  (user[:drugs] != "Never")
                        u.bodytype =  user[:body_type]
      end
    end

    def is_ignored(username, gender="Q")
      array = Array.new
      add_user(username, "Q", "ignore_list") unless existsCheck(username)
      result = @db.exec( "select ignore_list from matches where name=$1 and account=$2", [username, @login])
      result.each do |man|
        array.push(man)
      end
      array.shift["ignore_list"].to_i == 1
    end

    def ignore_user(username)
      unless existsCheck(username)
        puts "Adding user first: #{username}"
        add_user(username, "Q", "hidden_users")
      end
      unless is_ignored(username)
        puts "Added to ignore list: #{username}" if $verbose
        @db.exec( "update matches set ignore_list=$3 where name=$1 and account=$2", [username, @login, 1])
        @db.exec( "update matches set ignored=$3 where name=$1 and account=$2", [username, @login, true])
      else
        puts "User already ignored: #{username}" if $verbose
      end
    end

    def unignore_user(username)
      @db.exec( "update matches set ignore_list=0 where name=$1 and account=$2", [username, @login])
    end

    def unignore_user2(username)
      @db.exec( "update matches set ignore_list=0 where name=$1", [username])
    end

    def set_inactive(username)
      begin
        @db.exec( "update matches set inactive = true where name=$1", [username])
      rescue
        @db.exec( "insert into matches (name, inactive) values ($1, true)", [username])
      end
    end

    def added_from(username, method)
      @db.exec("update matches set added_from=$1 where name=$2 and account=$3", [method, username, @login])
    end

    def get_added_from(username)
      row = @db.exec("select added_from from matches where account=$1 and name=$2", [@login, username])
      row[0]["added_from"].to_s
    end

    def existsCheck(username)
      @db.exec( "select 1 where exists(
          select 1
          from matches
          where name = $1
          and account = $2
      ) ", [username, @login]).any?
    end

    def import_user(args)
      name = args[:name]
      distance = args[:distance]
      age = args[:age]
      counts = args[:counts]
      last_visit = args[:last_visit]
      gender = args[:gender]
      @db.exec("insert into matches (name, counts, gender, age, distance, last_visit) values ($1, $2, $3, $4, $5, $6)", [name, counts, gender, age, distance, last_visit])
    end

    def remove_unknown_gender
      @db.exec("delete from matches where gender=$1 and account=$2", ["Q", @login])
    end

    def close
      # @db.commit
      # @db.close
      puts "you missed one."
    end

    def exit_db
      @db.close
    end


    def commit
      @db.commit
    end

  end

    class User < Sequel::Model
      # set_primary_key [:name]
    end

    class IncomingMessage < Sequel::Model
      # set_primary_key [:message_id, :timestamp]
    end

    class Match < Sequel::Model
      # set_primary_key [:account, :name]
    end

    class UsernameChange < Sequel::Model

    end
end
