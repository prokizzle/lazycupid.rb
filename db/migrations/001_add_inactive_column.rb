
Sequel.migration do
  change do
    alter_table :matches do
      add_column :inactive, :boolean
    end
  end
end
