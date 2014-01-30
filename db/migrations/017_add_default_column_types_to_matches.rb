Sequel.migration do
	change do
		alter_table(:matches) do
			set_column_default :counts, 0
			set_column_default :distance, 0
			set_column_default :ignored, false
			set_column_default :last_visit, 0
			set_column_default :match_percent, 0
			set_column_default :last_online, 69552089750
		end
	end
end