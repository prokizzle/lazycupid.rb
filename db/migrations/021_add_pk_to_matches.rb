
Sequel.migration do
  change do
    alter_table :matches do
      add_primary_key(:id)
    end
  end
end
