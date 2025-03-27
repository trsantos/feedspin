class AddModifiedAtToFeeds < ActiveRecord::Migration[8.0]
  def change
    add_column :feeds, :modified_at, :datetime
  end
end
