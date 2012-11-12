require 'csv'

@username = "bostonboy86"
link_queue = Array.new(0)
visit_queue = Array.new(0)
CSV.foreach(@username + "_count.csv", :headers => true, :skip_blanks => false) do |row|
  text = row[0]
  count = row[1].to_i
  if count == 1
    visit_queue += [text]
  end
end

visit_queue.each do |user|
	
	link_queue += ["http://www.okcupid.com/profile/#{user}/"]
end

puts link_queue