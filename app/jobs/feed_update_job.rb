class FeedUpdateJob < ApplicationJob
  queue_as :low

  def perform(feed)
    feed.update_feed
    ActiveRecord::Base.connection.close
  rescue
    nil
  end
end
