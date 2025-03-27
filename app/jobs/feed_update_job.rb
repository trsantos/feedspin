class FeedUpdateJob < ApplicationJob
  queue_as :low

  def perform(feed)
    feed.update_feed
  rescue StandardError
    nil
  ensure
    ActiveRecord::Base.connection.close
  end
end
