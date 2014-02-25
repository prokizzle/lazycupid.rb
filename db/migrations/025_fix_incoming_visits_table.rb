
Sequel.migration do
  change do
      drop_column :incoming_visits, :server_sequid
      add_column :incoming_visits, :server_seqid, Integer
  end
end
