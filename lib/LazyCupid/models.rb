    class User < Sequel::Model
      # set_primary_key [:name]
    end

    class IncomingMessage < Sequel::Model
      # set_primary_key [:message_id, :timestamp]
    end

    class Match < Sequel::Model
      # set_primary_key [:account, :name]
    end

    class UsernameChange < Sequel::Model

    end

    class OutgoingVisit < Sequel::Model

    end

    class IncomingVisit < Sequel::Model
    end
