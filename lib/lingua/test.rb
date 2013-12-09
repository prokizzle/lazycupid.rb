require_relative 'lib/readability'

r = Lingua::EN::Readability.new("I'm an 'on the go' kind of girl. I generally spend my weekends finding things to do like plays & performances and/or checking out a new restaurant. I also love going on the hunt for a good cup of coffee and people watching. Yes, I'm one of those people with a computer at a coffeeshop. I enjoy taking my freelance work out and about with me instead of being cooped up at home.

I love gorgeous weekends in Boston and think they are best used by going to the Public Garden, biking along the Charles or walking through the Arboretum.")
puts r.kincaid.to_i
puts r.fog
