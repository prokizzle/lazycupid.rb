require 'rubygems'
require 'csv'
require 'set'

scannedIPs = Hash.new(0)

count = 0
names = Hash.new {|h, k| h[k] = 0 }
s = Set.new
CSV.foreach("danceyrselfcln.csv", :headers => true, :skip_blanks => false) do |row|

       text = row[0]
       # names[text] += 1 if text
       s.add(text)

end

s.each do |a| 
	names[a] = a.size

end

puts names["AmeliaIG"]