Sequel.migration do
  change do
    add_column :incoming_messages, :time, :time
  end
end