
Sequel.migration do
  change do
      drop_column :incoming_visits, :server_seqid
      drop_column :incoming_visits, :server_gmt
      add_column :incoming_visits, :server_seqid, String
      add_column :incoming_visits, :server_gmt, DateTime
  end
end
