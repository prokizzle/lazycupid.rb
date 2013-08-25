
Sequel.migration do
  change do
    create_table :users do
      String :name, :unique => true
      String :gender
      String :age
      String :sexuality
      String :city
      String :state
      Boolean :inactive, :default => false
      Float :height
      String :bodytype
      Boolean :drugs
      Boolean :smokes
      Boolean :drinks
      String :ethnicity
      Integer :last_online
      Boolean :likes_cats
      Boolean :likes_dogs


      primary_key(:name)

    end
  end
end
