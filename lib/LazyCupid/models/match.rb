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