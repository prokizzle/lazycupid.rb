Sequel.migration do
  change do
    create_table :incoming_messages do
      Integer :username
      String :account
      Integer :timestamp
    end
    alter_table :incoming_messages do
      add_primary_key(:id)
      add_index([:username, :account, :id, :timestamp])
    end
  end
end
