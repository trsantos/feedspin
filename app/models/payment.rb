class Payment < ApplicationRecord
  belongs_to :user

  def self.monthly_price
    3
  end

  def self.trial_duration
    2.weeks
  end
end
