class ChangeCancelAtPeriodEndFromUsers < ActiveRecord::Migration[7.2]
  def change
    change_column_null    :users, :cancel_at_period_end, false, false
    change_column_default :users, :cancel_at_period_end, false
  end
end
