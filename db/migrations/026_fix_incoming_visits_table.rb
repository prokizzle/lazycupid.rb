
Sequel.migration do
  change do
      drop_column :incoming_visits, :server_seqid
      add_column :incoming_visits, :server_seqid, String
  end
end
