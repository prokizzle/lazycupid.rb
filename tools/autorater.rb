require_relative '../lib/LazyCupid/auto_rater'
require 'highline/import'

$verbose = true
$driver = "phantomjs"
if ARGV.size > 0
  @username = ARGV[0]
  @password = ARGV[1]
else
  @username = ask("username: ")
  @password = ask("password: "){ |q| q.echo = "*" }
end

@autorater    = LazyCupid::AutoRater.new(username: @username, password: @password)

@autorater.login

loop do
  begin
    @autorater.rate
    sleep 2
  rescue SystemExit, Interrupt
    print "\nGoodbye!"
    @autorater.logout
  end
end
