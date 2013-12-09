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
      result = @db.get_my_last_visit_date(match_name)
      if result >1
        return Time.at(result).ago.to_words
      else
        return "never"
      end
    end

    def prev_visit(user)
      return @db.get_prev_visit(user)
    end
  end
end
