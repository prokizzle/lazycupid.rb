Sequel.migration do
  change do
    alter_table :matches do
      add_index([:name, :age, :match_percent, :account, :distance, :sexuality, :height, :gender, :ignored, :last_online, :counts, :last_visit])
    end
  end
end
