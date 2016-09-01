class SubscriptionsController < ApplicationController
  include ApplicationHelper

  before_action :logged_in_user
  before_action :correct_user, only: [:edit, :update, :destroy]

  def index
    user = current_user
    if user.subscriptions.empty?
      flash[:primary] = 'You are not subscribed to any feeds yet.'
      redirect_to user
    end
    @subscriptions =
      user.subscriptions.includes(:feed).order(starred: :desc, updated: :desc)
  end

  def create
    @feed = Feed.find(params[:feed_id])
    @user = current_user
    @subscription = @user.subscriptions.create(feed_id: @feed.id,
                                               visited_at: Time.current,
                                               updated: false)
    respond_to do |format|
      format.html { redirect_to @feed }
      format.js
    end
  end

  def edit
  end

  def update
    set_update_params
    @subscription.update_attributes(sub_params)
    @feed = @subscription.feed
    respond_to do |format|
      format.html { redirect_to @feed }
      format.js
    end
  end

  def destroy
    @feed = @subscription.feed
    @user.unfollow(@feed)
    @subscription = nil
    respond_to do |format|
      format.html { redirect_to @feed }
      format.js
    end
  end

  private

  def sub_params
    params.require(:subscription).permit(:title, :site_url, :starred)
  end

  def set_update_params
    set_update_title
    set_update_url
  end

  def set_update_title
    title = params[:subscription][:title]
    params[:subscription][:title] = nil if title && title.blank?
  end

  def set_update_url
    site_url = params[:subscription][:site_url]
    return if site_url.nil?
    params[:subscription][:site_url] = process_url site_url
  end

  def correct_user
    @subscription = Subscription.find(params[:id])
    @user = User.find(@subscription.user_id)
    redirect_to root_url unless current_user == @user
  end
end
