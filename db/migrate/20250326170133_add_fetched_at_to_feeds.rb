class AddFetchedAtToFeeds < ActiveRecord::Migration[8.0]
  def change
    add_column :feeds, :fetched_at, :datetime
  end
end
