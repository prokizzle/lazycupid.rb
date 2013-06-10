class GrowlNotifications
  attr_reader :last_message
  attr_accessor :last_message

  def initialize(args)
    @tracker = args[:tracker]
    @settings = args[:settings]
    @g = Growl.new "localhost", "#{@tracker.account}"
    @g.add_notification "lazy-cupid-notification"
  end

  def handle_notification(username, type)
    @username = username
    self.send(type) unless last_message == "#{type}::#{username}"
    last_message = "#{type}::#{username}"
  end

  def notify(user, type)
    @g.notify "lazy-cupid-notification", type, user if @settings.growl_new_mail
  end

  def new_message(username=@username)
    notify(@username, "New Message") if @settings.growl_new_mail
  end

  def new_visit(username=@username)
    notify(@username, "New Visit") if @settings.growl_new_visits
  end

end
