Sequel.migration do
  change do
    alter_table :stats do
      add_index([:new_users, :account])
    end
  end
end
