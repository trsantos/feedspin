class RemoveIsPremiumFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :is_premium, :string
  end
end
