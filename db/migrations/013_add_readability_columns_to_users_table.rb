
Sequel.migration do
  change do
      add_column :users, :fog, Integer
      add_column :users, :kincaid, Integer
      add_column :users, :flesch, Integer
  end
end
