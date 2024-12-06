class RemoveStripeSubscriptionIdFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :stripe_subscription_id, :string
  end
end
