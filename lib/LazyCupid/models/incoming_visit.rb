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