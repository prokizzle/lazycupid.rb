Sequel.migration do
  change do
    create_table(:matches) do
      Integer :id, :unique => true
      String :name, :null => false
      String :account, :null => false
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

    create_table(:users) do
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

    create_table(:ignore_list) do
      primary_key :id
      String :name
      String :account
      String :reason
    end

    create_table(:account) do
      primary_key :account
      Integer :id
      String :account, :unique => true
      Integer :total_messages_received
      Integer :total_incoming_visits
      Integer :total_outgoing_visits
    end

    create_table(:messages) do
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

    create_table(:incoming_visits) do
      primary_key :id
      String :name
      String :account
      Integer :visit_date
    end

    create_table(:outgoing_visits) do
      primary_key :id
      String :name
      String :account
      Integer :date_visited
    end
  end
