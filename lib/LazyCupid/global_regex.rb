# Site-wide Regular Expressions
#
# In order to be able to test to ensure working expressions for OKCupid
# site changes, it may be helpful to have a constants file with regular
# expressions stored as strings in one place. This will make it easier to
# update the code and write tests for important regular expressions


# Profile
#
$inactive_profile               = Regexp.new(/\bwe don’t have anyone by that name\b/)
$handle                         = Regexp.new(/<div class="userinfo"> <div class="details"> <p class="username">(.+)<.p> <p class="info">/)
$relative_distance              = Regexp.new(/\((\d+) miles*\)/)

# Messages
# @url http://www.okcupid.com/messages
#
$total_messages                 = Regexp.new(/href="\/messages\?low\=(\d+)\&amp\;folder\=1">\d+/)
$no_messages                    = Regexp.new(/No messages\!/)

# Harvester
#
$details                        = Regexp.new(/\/([\w\s_-]+)\?cf=regular".+<p class="aso" style="display:"> (\d{2})<span>&nbsp;\/&nbsp;<\/span> (M|F)<span>&nbsp;\/&nbsp;<\/span>(\w)+<span>&nbsp;\/&nbsp;<\/span>\w+ <\/p> <p class="location">([\w\s-]+), ([\w\s]+)<\/p>/)
$matches_list                   = Regexp.new(/"usr-([\w\d]+)"/)
$home_page_matches              = Regexp.new(/class="username".+\/profile\/([\d\w]+)\?cf=home_matches.+(\d{2})\s\/\s(F|M)\s\/\s([\w\s]+)\s\/\s[\w\s]+\s.+"location".([\w\s]+)..([\w\s]+)/)
$leftbar_matches                = Regexp.new(/\/([\w\d_-]+)\?cf\=leftbar_match/)
$similar_users                  = Regexp.new(/\/([\w\d _-]+)....profile_similar/)

# Browser
#
$account_status_deactivated     = Regexp.new(/\bRestore your account\b/)
$account_status_wrong_password  = Regexp.new(/\byour info was incorrect\b/)
$account_status_logged_out      = Regexp.new(/logged_out/)
$account_status_deleted         = Regexp.new(/\baccount was deleted\b/)
$account_handle                 = Regexp.new(/\/profile\/(.+)/)

