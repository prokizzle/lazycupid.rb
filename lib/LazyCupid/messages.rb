module LazyCupid

  class Messages

    def send_message(recipient, body, session_object)
      @account = session_object
      body = encodeURI(body)
      url = "http://api.okcupid.com/instantevents?send=1&recipient=#{recipient}&topic=false&body=#{body}"
      @account.go_to(url)
    end
  end
end
