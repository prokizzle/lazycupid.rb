
Sequel.migration do
  change do
    create_table :incoming_visits do
      String :name
      String :account
      String :server_gmt
      String :server_seqid
      primary_key(:server_sequid)
    end
  end
end
