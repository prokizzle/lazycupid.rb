
Sequel.migration do
  change do
    alter_table :outgoing_visits do
      add_primary_key(:id)
    end
  end
end
