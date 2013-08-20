
Sequel.migration do
  change do
    alter_table :matches do
      drop_column :inactive
      add_column :inactive, :boolean, :default => false
    end
  end
end
