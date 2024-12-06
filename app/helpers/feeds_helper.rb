module FeedsHelper
  def sub_title(feed)
    @subscription&.title || feed.title || "[#{feed.feed_url}]"
  end

  def sub_url(feed)
    @subscription&.site_url || feed.site_url || feed.feed_url
  end

  def favicon_for(url)
    uri = URI.parse url
    "https://icons.duckduckgo.com/ip2/#{uri.host}.ico"
  rescue StandardError
    image_path 'feed-icon.png'
  end

  def show_payment_aside?
    Time.current > @user.expiration_date - Payment.trial_duration && @user.stripe_subscription_status.nil?
  end
end
