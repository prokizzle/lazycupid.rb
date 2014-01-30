Sequel.migration do
	change do
		alter_table(:matches) do
      		add_column :ages, :integer, :default => 25
		end
	end
end