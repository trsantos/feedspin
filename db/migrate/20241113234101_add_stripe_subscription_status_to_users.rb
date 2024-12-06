class AddStripeSubscriptionStatusToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :stripe_subscription_status, :string
  end
end
