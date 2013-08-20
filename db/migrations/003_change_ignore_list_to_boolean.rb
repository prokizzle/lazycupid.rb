
Sequel.migration do
  change do
    alter_table :matches do
      drop_column :ignored
      add_column :ignored, :boolean, :default => false
    end
  end
end
