require 'uuidtools'
require 'pg'
require 'progress_bar'
require 'sequel'

module LazyCupid

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
      puts "Connecting to database..." if $verbose
      $db           = Sequel.connect($db_url)
      require_relative 'models'
      @did_migrate  = false
      @login        = args[:login_name]
      $login        = @login
      @settings     = args[:settings]
      # @db           = PGconn.connect( :dbname => @settings.db_name,
      # :password => @settings.db_pass,
      # :user => @settings.db_user,
      # :host => @settings.db_host
      # )
      # tasks     = args[:tasks] unless @settings.debug
      #db_tasks #if args[:tasks]
      @verbose      = @settings.verbose
      @debug        = @settings.debug
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

    def guess_distance(city, state)
      return Match.where(:city => city, :account => @login, :state => state).avg(:distance).to_i
      # state_avg_distance = Match.where(:state => state, :account => account).avg(:distance).to_i
    end

    def set_estimated_distance(user, city, state)
      Match.where(:name => user, :account => login).update(:distance => guess_distance(city, state))
    end

    def add_message(args)
      user = args[:username]
      message_id = args[:message_id]
      timestamp = args[:timestamp]

      # @db.exec("insert into incoming_messages(account, username, message_id, timestamp) values($1, $2, $3, $4)", [@login, user, message_id, timestamp])
      IncomingMessage.find_or_create(message_id: message_id, account: @login).update(:timestamp => timestamp, :username => user )

    end

    def set_location(args)
      user = args[:user]
      city = args[:city]
      state = args[:state]
      distance = guess_distance(city, state)
      @db.exec("update matches set distance=$1, city=$2, state=$3 where name=$4 and account=$5", [distance, city, state, user, @login])
    end

    def stats_add_visit(name)
      @db.exec("update stats set total_visits=total_visits + 1 where account=$1", [@login])
      @db.exec("insert into outgoing_visits(name, account, timestamp) values($1,$2,$3)", [name, @login, Time.now.to_i])
    end

    def stats_add_visitor
      Stat.where(account: @login).update(total_visitors: Sequel.expr(1) + :total_visitors)
    end

    def stats_add_new_user
      Stat.where(account: @login).update(new_users: Sequel.expr(1) + :new_users)
    end

    def stats_add_new_message
      Stat.where(account: @login).update(total_messages: Sequel.expr(1) + :total_messages)
    end

    def stats_get_visitor_count
      return Stat.where(account: @login).first.to_hash[:total_visitors]
    end

    def stats_get_visits_count
      return Stat.where(account: @login).first.to_hash[:total_visits]

    end

    def stats_get_new_users_count
      return Stat.where(account: @login).first.to_hash[:new_users]
    end

    def stats_get_total_messages
      return Stat.where(account: @login).first.to_hash[:total_messages]
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
      if user[:city]
        distance = guess_distance(user[:city], user[:state])
      else
        distance = 0
      end

      Match.find_or_create(:name => user[:username], :account => @login) do |u|
        u.gender = user[:gender]
        u.age = user[:age] if user[:age]
        u.city = user[:city] if user[:city]
        u.state = user[:state] if user[:state]
        u.distance = distance if distance
        u.added_from ||= user[:added_from]
        u.inactive = false
      end
    end

    def add(user)

      # unless existsCheck(user[:username]) || user[:username] == "pictures"
      puts "Adding user:        #{user[:username]}" if $verbose

      distance = guess_distance(user[:city], user[:state]) unless user[:distance]

      #   @db.exec("insert into matches(name, ignore_list, time_added, account, counts, gender, added_from, city, state, distance, match_percent, age) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)", [user[:username], 0, Time.now.to_i, @login.to_s, 0, user[:gender], user[:added_from], user[:city], user[:state], distance, user[:match_percent], user[:age]])
      # else
      #   @db.exec("update matches set inactive=false where name=$1", [user[:username]])
      #   puts "User already in db: #{user[:username]}" if $verbose
      # end

      Match.find_or_create(:name => user[:username], :account => @login) do |u|
        u.age = user[:age]
        u.match_percent = user[:match_percent]
        u.distance = distance || user[:distance]
        u.time_added = Time.now.to_i if u.time_added.nil?
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
      Match.where(:account => @login, :name => user).first.to_hash[:counts]
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
      max_counts          = @settings.max_followup
      query_size          = 30
      min_distance        = 0

      sexualities = [nil]
      sexualities << "Gay"      if @settings.visit_gay
      sexualities << "Bisexual" if @settings.visit_bisexual
      sexualities << "Straight" if @settings.visit_straight

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
      # order by #{sort_1}, #{sort_2}, #{sort_3}, #{sort_4}, #{sort_5}, #{sort_6}, #{sort_7}
      # result = Match.filter(
      #   :account => @login,
      #   :ignored => [false, nil],
      #   :inactive => [false, nil]).where{
      #   last_visit < min_time.to_i
      # }



      # result = Match.join_table(:left, :users, :name => :name).filter(
      result = Match.filter(
        :account => @login,
        :ignored => false,
        :inactive => false,
        :distance => 0..$max_distance.to_i,
        :age => min_age.to_i..max_age.to_i,
        :last_visit => 0..min_time.to_i,
        :counts => 0..max_counts.to_i,
        :match_percent => $min_percent.to_i..102,
        :gender => [desired_gender.to_s, alt_gender.to_s]
      ).order(Sequel.desc(:match_percent)).take(query_size).to_a

      # puts result.first.to_hash
      if result.empty?
        Match.filter(:account => $login).where(:gender => nil).update(:gender => $gender)
        Match.where(:name => nil).delete
        Match.where(:distance => nil).update(:distance => 0)
        Match.where(:match_percent => nil).update(:match_percent => 100)

        User.where(:name => nil).delete
        User.where(:age => nil).update(:age => 25)
        # User.where(:gender => nil).update(:gender => $gender)
        User.where(:inactive => nil).update(:inactive => false)
      end

      return result
    end

    def user_record_exists(user)
      @db.exec( "select exists(select * from matches where name=$1 and account=$2", [user, @login] )
    end

    def increment_visitor_counter(visitor)
      Match.find_or_create(name: visitor, account: @login).update(visit_count: Sequel.expr(1) + :visit_count)
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
      result[0]["last_visit"].to_i
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
      Match.where(name: visitor, account: @login).update(visitor_timestamp: timestamp)
    end

    def get_visitor_timestamp(visitor)
      IncomingVisit.where(account: @login, name: visitor).first[:server_gmt] rescue 0
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

        Match.where(:name => user[:handle], :account => @login).update(
          :gender => user[:gender],
          :counts => Sequel.expr(1) + :counts,
          :gender         => user[:gender],
          :sexuality      => user[:sexuality],
          :match_percent  => user[:match_percent],
          :state          => user[:state],
          :city           => user[:city],
          :height         => user[:height],
          :last_online    => user[:last_online],
          :last_visit     => Time.now.to_i,
          :friend_percent => user[:friend_percentage],
          :enemy_percent  => user[:enemy_percentage],
          :distance       => user[:distance],
          :age            => user[:age]
        )
        User.find_or_create(:name => user[:handle]) do |u|
          u.age         =  user[:age]
          u.gender      =  user[:gender]
          u.sexuality   =  user[:sexuality]
          # u.relationship_status =  user[:relationship_status]
          u.city        =  user[:city]
          u.state       =  user[:state]
          u.height      =  user[:height]
          u.last_online =  user[:last_online]
          u.smokes      =  (user[:smoking] != "No")
          u.drinks      =  (user[:drinking] != "Not at all")
          u.bodytype    = user[:bodytype]
          u.ethnicity   = user[:ethnicity]
          u.drugs       =  (user[:drugs] != "Never")
          u.bodytype    =  user[:body_type]
          u.fog         = user[:fog]
          u.kincaid     = user[:kincaid]
          u.flesch      = user[:flesch]
        end

        OutgoingVisit.create(:name => user[:handle], :account => @login, :timestamp => Time.now.to_i)

        # Stat.find_or_create(:account => @login) do |u|
        #   u.total_visits += 1 rescue u.total_visits = 1
        # end


        # increment_visit_count(user[:handle])
        # set_my_last_visit_date(user[:handle])
        # set_user_details(user)
        # p "Height: #{user[:height]}" if $debug
      end
      # stats_add_visit(user[:handle])
    end


    # TBD
    # def set_user_details(user)

    #   Match.where(:name => user[:handle]).update(
    #     :gender         => user[:gender],
    #     :sexuality      => user[:sexuality],
    #     :match_percent  => user[:match_percent],
    #     :state          => user[:state],
    #     :city           => user[:city],
    #     :height         => user[:height],
    #     :last_online    => user[:last_online],
    #     :last_visit     => Time.now.to_i,
    #     :friend_percent => user[:friend_percentage],
    #     :enemy_percent  => user[:enemy_percentage],
    #     :distance       => user[:distance],
    #     :age            => user[:age]
    #     )

    #   User.find_or_create(:name => user[:handle]) do |u|
    #                     u.age         =  user[:age]
    #                     u.gender      =  user[:gender]
    #                     u.sexuality   =  user[:sexuality]
    #                     # u.relationship_status =  user[:relationship_status]
    #                     u.city        =  user[:city]
    #                     u.state       =  user[:state]
    #                     u.height      =  user[:height]
    #                     u.last_online =  user[:last_online]
    #                     u.smokes      =  (user[:smoking] != "No")
    #                     u.drinks      =  (user[:drinking] != "Not at all")
    #                     u.bodytype    = user[:bodytype]
    #                     u.ethnicity   = user[:ethnicity]
    #                     u.drugs       =  (user[:drugs] != "Never")
    #                     u.bodytype    =  user[:body_type]
    #   end
    # end

    def ignore_user(username)
      puts "Added to ignore list: #{username}" if $verbose
      Match.find_or_create(:name => username, account: @login) do |m|
        m.gender ||= "Q"
        m.ignored = true
        m.distance = 1
      end
      # m.save
    end

    def unignore_user(username)
      @db.exec( "update matches set ignore_list=0 where name=$1 and account=$2", [username, @login])
    end

    def unignore_user2(username)
      @db.exec( "update matches set ignore_list=0 where name=$1", [username])
    end

    def set_inactive(username)
      Match.find_or_create(name: username).update(inactive: true)
      User.find_or_create(name: username).update(inactive:true)
    end

    def added_from(username, method)
      @db.exec("update matches set added_from=$1 where name=$2 and account=$3", [method, username, @login])
    end

    def get_added_from(username)
      row = @db.exec("select added_from from matches where account=$1 and name=$2", [@login, username])
      row[0]["added_from"].to_s
    end

    # TDB
    # def existsCheck(username)
    #   @db.exec( "select 1 where exists(
    #       select 1
    #       from matches
    #       where name = $1
    #       and account = $2
    #   ) ", [username, @login]).any?
    # end

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

end
