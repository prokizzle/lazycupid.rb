Sequel.migration do
	change do
		alter_table(:matches) do
  			set_column_type :age, Integer
		end
	end
end