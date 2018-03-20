
Sequel.migration do
  change do
    alter_table :stats do
      add_primary_key(:id)
    end
  end
end
