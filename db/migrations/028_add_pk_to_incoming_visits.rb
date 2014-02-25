
Sequel.migration do
  change do
    alter_table :incoming_visits do
      add_primary_key(:id)
    end
  end
end
