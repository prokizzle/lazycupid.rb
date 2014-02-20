module LazyCupid
  class Lookup
    attr_reader :match, :data, :visits
    attr_accessor :match, :data, :visits

    def initialize(args)
      @db = args[ :database]
      # @db.import if manual_import
    end

    def visited(user)
      return @db.get_visit_count(user)
    end

    def were_visited(user)
      return @db.get_visitor_count(user)
    end

    def last_visited(match_name)
      return Match.where(:account => $login, :name => match_name).first[:last_visit]
    end

    def prev_visit(user)
      return @db.get_prev_visit(user)
    end
  end
end
