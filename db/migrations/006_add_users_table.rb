
Sequel.migration do
  change do
    create_table :users do
      String :name, :unique => true
      String :gender
      Integer :age
      String :sexuality
      String :city
      String :state
      Boolean :inactive, :default => false
      Float :height
      String :bodytype
      Boolean :drugs, :default => false
      Boolean :smokes, :default => false
      Boolean :drinks, :default => false
      String :ethnicity
      Integer :last_online, :default => 0
      Boolean :likes_cats, :default => false
      Boolean :likes_dogs, :default => false


      primary_key(:name)

    end
  end
end
