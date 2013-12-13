
Sequel.migration do
  change do
      drop_column :incoming_messages, :username
      add_column :incoming_messages, :username, String
  end
end
