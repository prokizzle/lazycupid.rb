Sequel.migration do
  change do
    alter_table :matches do
      add_index([:name, :account])
    end
  end
end
