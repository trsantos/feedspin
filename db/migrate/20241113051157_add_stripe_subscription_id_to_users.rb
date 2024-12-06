class AddStripeSubscriptionIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :stripe_subscription_id, :string
    add_index :users, :stripe_subscription_id
  end
end
