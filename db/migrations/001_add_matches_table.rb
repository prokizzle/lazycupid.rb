
Sequel.migration do
  change do
    create_table :matches do
      String :name
      String :account
      Integer :counts
      Boolean :ignored, :default => false
      Integer :visitor_timestamp
      Integer :visit_count
      Integer :last_visit, :default => 0
      String :gender
      String :age
      String :sexuality
      String :city
      String :state
      Integer :time_added
      String :added_from
      Integer :match_percentage
      Integer :match_percent
      String :relationship_status
      Boolean :inactive, :default => false
      Float :height
      String :bodytype
      String :kids
      Integer :distance
      Integer :enemy_percent
      Integer :friend_percent
      Boolean :drugs
      Boolean :smokes
      Boolean :drinks
      String :ethnicity
      Integer :last_online
      Boolean :likes_cats
      Boolean :likes_dogs
      Integer :ignore_list

    end
    create_table :stats do
    	Integer :total_visits
    	Integer :total_visitors
    	Integer :new_users
    	Integer :total_messages
    	String :account
    end

  end
end
