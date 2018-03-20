module LazyCupid
  require_relative '../lib/LazyCupid/browser'
  require 'highline/import'

  username = ask("username: ")
  password = ask("password: "){ |q| q.echo = "*" }
  browser = LazyCupid::Browser.new(username: username, password: password)
  browser.login
  loop do
    puts ""
    url = ask("url: ")

    request_id            = (1..266).to_a.sample

    browser.send_request(url, request_id)

    print "Requesting page..."
    resp = {ready: false}
    until resp[:ready] == true
      resp = browser.get_request(request_id)
      # p resp
    end
    puts " done."
    puts resp[:body]
  end
end
