class Stat < Sequel::Model
  set_primary_key :id
  def validate
    super
    errors.add(:account, 'cannot be null') if account.nil?
  end
end