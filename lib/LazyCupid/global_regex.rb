# Site-wide Regular Expressions
#
# In order to be able to test to ensure working expressions for OKCupid
# site changes, it may be helpful to have a constants file with regular 
# expressions stored as strings in one place. This will make it easier to
# update the code and write tests for important regular expressions


# Profile

# Messages
# @url http://www.okcupid.com/messages
#
$total_messages = Regexp.new(/Message storage.*(\d+) of/)
$no_messages = Regexp.new(/No messages\!/)
