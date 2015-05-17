class SubscriptionsController < ApplicationController
  include ApplicationHelper
  include FeedsHelper
  
  before_action :logged_in_user
  before_action :correct_user, only: [:edit, :update, :destroy]

  def index
    @subscriptions = current_user.subscriptions.sort_by { |s| sub_title(s.feed) || "" }
  end

  def create
    feed = Feed.find(params[:feed_id])
    current_user.follow(feed)
    redirect_to feed
  end

  def edit
    @subscription = Subscription.find(params[:id])
  end

  def update
    @subscription = Subscription.find(params[:id])
    if @subscription.update_attributes(sub_params)
      feed = Feed.find(@subscription.feed_id)
      redirect_to feed
    end
  end

  def destroy
    feed = Feed.find(Subscription.find(params[:id]).feed_id)
    current_user.unfollow(feed)
    redirect_to feed
  end

  def next
    id       = current_user.id
    interval = 8.hour.ago
    query    = "user_id = ? AND starred = ? AND visited_at < ?"
    fav      = Subscription.where(query, id, true,  interval)
    normal   = Subscription.where(query, id, false, interval)
    if s = get_updated_subscription(fav) || get_updated_subscription(normal)
      redirect_to s
    else
      flash[:info] = "You have no updated feeds. Check back later!"
      redirect_to root_url
    end
  end
  
  private

  def sub_params
    params.require(:subscription).permit(:title, :site_url, :starred)
  end

  def correct_user
    @user = User.find(Subscription.find(params[:id]).user_id)
    redirect_to root_url unless current_user?(@user) or current_user.admin?
  end

  def get_updated_subscription(slist)
    slist.shuffle.each do |s|
      f = s.feed
      f.update
      if s.updated?
        return f
      end
    end
    return nil
  end
end
