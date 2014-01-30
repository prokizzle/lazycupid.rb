Sequel.migration do
	change do
		alter_table(:matches) do
			set_column_default :match_percent, 100
			set_column_default :last_online, 2086563760
		end
	end
end