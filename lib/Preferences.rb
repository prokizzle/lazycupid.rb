require './includes'

class Preferences
    def initialize(args)
        @browser = args[ :browser]
    end

    def raw
        @browser.current_user
    end

    def body
        @browser.body
    end

    def get_match_preferences
        @browser.go_to("http://www.okcupid.com/profile")
        gentation = raw.parser.xpath("//li[@id='ajax_gentation']").to_html
        ages = raw.parser.xpath("//li[@id='ajax_ages']").to_html
        location = raw.parser.xpath("//span[@id='ajax_location']")
        @looking_for = /(\w+) who like/.match(gentation)[1]
        @min_age = (/(\d{2}).+(\d{2})/).match(ages)[1]
        @max_age = (/(\d{2}).+(\d{2})/).match(ages)[2]
        @my_city = (/[\w\s]+,\s([\w\s]+)/).match(location)[1]
        # <li id="ajax_ages">Ages 20&ndash;35</li>
        puts @min_age, @max_age, @my_city, @looking_for
    end

end

module Settings
  # again - it's a singleton, thus implemented as a self-extended module
  extend self

  @_settings = {}
  attr_reader :_settings

  # This is the main point of entry - we call Settings.load! and provide
  # a name of the file to read as it's argument. We can also pass in some
  # options, but at the moment it's being used to allow per-environment
  # overrides in Rails
  def load!(filename, options = {})
    newsets = YAML::load_file(filename).deep_symbolize
    newsets = newsets[options[:env].to_sym] if \
                                               options[:env] && \
                                               newsets[options[:env].to_sym]
    deep_merge!(@_settings, newsets)
  end

  # Deep merging of hashes
  # deep_merge by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
  def deep_merge!(target, data)
    merger = proc{|key, v1, v2|
      Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    target.merge! data, &merger
  end

  def method_missing(name, *args, &block)
    @_settings[name.to_sym] ||
    fail(NoMethodError, "unknown configuration root #{name}", caller)
  end

end

