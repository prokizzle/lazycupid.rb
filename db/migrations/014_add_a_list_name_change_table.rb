Sequel.migration do
  change do
    create_table :username_changes do
      String :old_name
      String :new_name
    end
    alter_table :username_changes do
      add_primary_key(:id)
      add_index([:old_name, :new_name, :id])
    end
  end
end
