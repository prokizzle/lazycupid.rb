  $db           = Sequel.connect("postgres://***REMOVED***:***REMOVED***ec2-54-197-240-180.compute-1.amazonaws.com:5432/dbdqbruel10dk6")
class User < Sequel::Model
  set_primary_key :id
end

class IncomingMessage < Sequel::Model
  # set_primary_key [:message_id, :account]
end

class Match < Sequel::Model
  # set_primary_key [:account, :name]
  set_primary_key :id
  gender ||= "Q"

  def validate
    super
    errors.add(:distance, 'cannot be null') if distance.nil?
    errors.add(:gender, 'cannot be null') if gender.nil?
  end
end

Match.plugin :timestamps, :create=>:created_on, :update=>:updated_on

class UsernameChange < Sequel::Model

end

class OutgoingVisit < Sequel::Model

end

class IncomingVisit < Sequel::Model
  set_primary_key :id

  def validate
    super
    errors.add(:server_seqid, 'already exists') if server_seqid && new? && IncomingVisit.where(server_seqid: server_seqid).exists
    errors.add(:server_gmt, 'cannot be null') if server_gmt.nil?
    errors.add(:server_seqid, 'cannot be null') if server_seqid.nil?
    errors.add(:server_seqid, 'must be a string') unless server_seqid.is_a? String
    errors.add(:server_gmt, 'must be a time') unless server_gmt.is_a? Time

  end
end

class Stat < Sequel::Model
  set_primary_key :id
  def validate
    super
    errors.add(:account, 'cannot be null') if account.nil?
  end
end
