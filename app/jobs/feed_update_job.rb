class FeedUpdateJob < ApplicationJob
  queue_as :low

  def perform(feed)
    feed.update_feed
    ActiveRecord::Base.connection.close
  rescue StandardError
    nil
  end
end
