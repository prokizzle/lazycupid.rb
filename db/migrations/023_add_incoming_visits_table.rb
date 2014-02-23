
Sequel.migration do
  change do
    create_table :incoming_visits do
      String :name
      String :account
      Integer :server_gmt
      Integer :server_sequid
      primary_key(:server_sequid)
    end
  end
end
