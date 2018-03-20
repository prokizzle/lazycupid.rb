
Sequel.migration do
  change do
    create_table :outgoing_visits do
      String :name
      String :account
      Integer :timestamp
    end
  end
end
