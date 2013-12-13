require 'sequel'
require 'pg'
require 'progress_bar'

module LazyCupid
  class DatabaseManager
    attr_reader :accounts, :users
    def initialize(args)
      @login    = args[:login_name]
      @settings = args[:settings]


      @sequel = Sequel.connect(
        :adapter =>   @settings.db_adapter,
        :host =>      @settings.db_host,
        :database =>  @settings.db_name,
        :user =>      @settings.db_user,
        :password =>  @settings.db_pass
      )
      # begin
      # create_tables
      # rescue
      # puts "Tables already created"
      # end

      # @old_db = Sequel.connect(
      #   :adapter =>   @settings.db_adapter,
      #   :host =>      @settings.db_host,
      #   :database =>  @settings.db_name,
      #   :user =>      @settings.db_user,
      #   :password =>  @settings.db_pass,
      # )

      @pg = PGconn.connect( :dbname => 'lazy_cupid',
                            :password => '123456',
                            :user => '***REMOVED***'
                            )


      @accounts         = @db[:account]
      @matches          = @db[:matches]
      @users            = @db[:users]
      @ignore_list      = @db[:ignore_list]
      @messages         = @db[:messages]
      @incoming_visits  = @db[:incoming_visits]
      @outgoing_visits  = @db[:outgoing_visits]
    end

    def session
      self
    end

    def create_tables
      @db.create_table :matches do
        Integer :id, :unique => true
        String :name
        String :account
        Integer :their_last_visit
        Integer :my_last_visit
        Integer :times_they_visited
        Integer :times_i_visited
        Integer :match_percentage
        Integer :friend_percentage
        Integer :enemy_percentage
        Integer :relative_distance
        String :added_from
        primary_key [:account, :name]
      end

      @db.create_table :users do
        String :name, :unique => true
        Integer :age
        String :gender
        String :sexuality
        String :relationship_status
        String :city
        String :state
        Float :height
        Integer :last_online
        String :smoking
        String :drinking
        String :drugs
        Integer :profile_length
        Integer :questions_answered
        TrueClass :cat_person
        TrueClass :dog_person
        String :education
        String :body_type
        String :thumbnail_url
        String :primary_photo_url
        primary_key :name
      end

      @db.create_table :ignore_list do
        primary_key :id
        String :name
        String :account
        String :reason
      end

      @db.create_table :account do
        primary_key :account
        Integer :id
        String :account, :unique => true
        Integer :total_messages_received
        Integer :total_incoming_visits
        Integer :total_outgoing_visits
      end

      @db.create_table :messages do
        primary_key :message_id
        String :sender
        String :account
        Integer :date_received
        Integer :server_gmt
        Integer :server_seqid
        Integer :message_length
        String :thread_url
        TrueClass :is_active
        Integer :message_id
      end

      @db.create_table :incoming_visits do
        primary_key :id
        String :name
        String :account
        Integer :visit_date
      end

      @db.create_table :outgoing_visits do
        primary_key :id
        String :name
        String :account
        Integer :date_visited
      end
    end

    def total_messages_received(account)
      @pg.exec("select count(last_msg_time) from matches where last_msg_time > 1 and account=$1", [@login]).each {|r| @result = r["count"]}
      @result
    end

    def total_incoming_visits(account)
      @pg.exec("select count(visitor_timestamp) from matches where visitor_timestamp > 1 and account=$1", [@login]).each {|r| @result = r["count"]}
      @result
    end

    def total_outgoing_visits(account)
      @pg.exec("select count(last_visit) from matches where last_visit > 1 and account=$1", [@login]).each {|r| @result= r["count"]}
      @result
    end

    def test_acc
      @pg.exec("select * from matches where account=$1", [@login]).each {|r| p r}
    end

    def add_to_matches(args)
      unless args["name"].nil?
        handle  = args["name"]
        account = args["account"]
        begin
          @matches.insert(:name => handle,
                          :account => account,
                          :my_last_visit => args["last_visit"],
                          :their_last_visit => args["visitor_timestamp"],
                          :match_percentage => args["match_percent"],
                          :friend_percentage => args["friend_percent"],
                          :enemy_percentage => args["enemy_percent"],
                          :relative_distance => args["distance"],
                          :added_from => args["added_from"])
        rescue

          @matches.where(:name => args["name"], :account => args["account"]).update(:name => handle)
        end
        # puts user[:name]
      end
    end

    def add_to_users(args)
      unless args["name"].nil?
        user = Hash.new(

        )
          @users.find_or_create(:name => args["name"]) do |user|

                        user.age =  args["age"]
                        user.gender =  args["gender"]
                        user.sexuality =  args["sexuality"]
                        user.relationship_status =  args["relationship_status"]
                        user.city =  args["city"]
                        user.state =  args["state"]
                        user.height =  args["height"]
                        user.last_online =  args["last_online"]
                        user.smoking =  args["smoking"]
                        user.drinking =  args["drinking"]
                        user.drugs =  args["drugs"]
                        user.body_type =  args["body_type"]
            end

      end
    end

    def add_to_ignore_list(args)
      unless args["name"].nil?

        user = Hash.new(

        )
        begin
          @ignore_list.insert(:account => user["account"],
                              :name => user["name"])
        rescue
          @ignore_list.where(:name => user["name"], :account => user["account"]).update(:account => user["account"],
                                                                                        :name => user["name"])
        end
      end
    end

    def test_users
      @users.where(:city => "Milford", :state=>"Connecticut")
    end

    def add_account
      account = Hash.new(
        :account => @login,
        :total_messages_received => total_messages_received(@login),
        :total_incoming_visits => total_incoming_visits(@login),
        :total_outgoing_visits => total_outgoing_visits(@login)
      )
      begin
        @accounts.insert(account)
      rescue
        @accounts.where(:account => args["account"]).update(account)
      end
    end


    def migrate
      create_tables
      add_account
      # data = @old_db.where(:account => @login)
      data = @pg.exec("select * from matches where account=$1", [@login])
      bar = ProgressBar.new(data.to_a.size)
      data.each do |entry|
        unless entry["account"].nil? && entry["name"].nil?
          # p entry
          # sleep 2
          add_to_matches(entry)
          add_to_users(entry)
          # if user["ignore_list"] == 1
          # add_to_ignore_list(user)
          # end
          # @outgoing_visits.insert(
          # :name => user["name"],
          # :account => user[:account],
          # :date_visited => user[:last_visit]
          # )
          # @incoming_visits.insert(
          # :name => user["name"],
          # :account => user["account"],
          # :visit_date => user["visitor_timestamp"]
          # )
          # unless user[:last_msg_time].nil?
          # @messages.insert(
          # :sender => user["name"],
          # :account => user["account"],
          # :date_received => user["last_msg_time"]
          # )
          # end
        end
        bar.increment!
      end

    end

    def followup_query
      min_time            = Chronic.parse("#{@settings.days_ago.to_i} days ago").to_i
      desired_gender      = @settings.gender,
        min_age             = @settings.min_age,
        max_age             = @settings.max_age,
        age_sort            = @settings.age_sort,
        height_sort         = @settings.height_sort,
        last_online_cutoff  = @settings.last_online_cutoff,
        min_counts          = 1,
        max_counts          = @settings.max_followup,
        min_percent         = @settings.min_percent,
        visit_gay           = @settings.visit_gay,
        visit_bisexual      = @settings.visit_bisexual,
        visit_straight      = @settings.visit_straight,
        distance            = @settings.max_distance

      result = @matches.where(
        :gender => desired_gender
      )
    end
  end

end
