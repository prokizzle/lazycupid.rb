
opposite_sex = gender == 'M' ? "F" : "M"

if bisexual-m
  visit straight-f
  visit bisexual-f
  visit bisexual-m
  visit gay-m

if bisexual-f
  visit straight-m
  visit bisexual-m
  visit bisexual-f
  visit gay-f

if straight-m
  visit straight-f
  visit bisexual-f

if straight-f
  visit straight-m
  visit bisexual-m

if gay-m
  visit gay-m
  visit bisexual-m

if gay-f
  visit gay-f
  visit bisexual-f
