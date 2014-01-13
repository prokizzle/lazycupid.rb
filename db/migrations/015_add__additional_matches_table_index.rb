Sequel.migration do
  change do
    alter_table :matches do
      add_index([:name, :match_percent, :account, :distance, :gender, :counts, :last_visit, :time_added, :added_from, :city, :state, :inactive])
    end
  end
end
