class AddCancelAtPeriodEndToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :cancel_at_period_end, :bool
  end
end
