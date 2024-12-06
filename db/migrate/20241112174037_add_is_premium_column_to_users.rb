class AddIsPremiumColumnToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_premium, :boolean, default: false
  end
end
