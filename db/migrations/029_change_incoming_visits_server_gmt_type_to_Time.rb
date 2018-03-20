
Sequel.migration do
  change do
      drop_column :incoming_visits, :server_gmt
      add_column :incoming_visits, :server_gmt, Time
  end
end
