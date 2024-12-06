class AddSnoozedAtToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :snoozed_at, :datetime
  end
end
