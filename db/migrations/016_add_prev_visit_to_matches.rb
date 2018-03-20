
Sequel.migration do
  change do
    alter_table :matches do
      add_column :prev_visit, :integer
    end
  end
end
