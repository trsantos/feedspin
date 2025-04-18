class SubscriptionsController < ApplicationController
  include ApplicationHelper

  before_action :logged_in_user
  before_action :correct_user, only: %i[edit update destroy]

  def index
    user = current_user
    if user.subscriptions.empty?
      flash[:primary] = 'You are not subscribed to any feeds yet.'
      redirect_to user
    end
    @subscriptions = user.subscriptions.includes(:feed).order('feed.title')
  end

  def create
    @feed = Feed.find(params[:feed_id])
    @user = current_user
    @subscription = @user.subscriptions.create(feed: @feed)
    respond_to do |format|
      format.html { redirect_to @feed }
      format.js
    end
  end

  def edit; end

  def update
    set_update_params
    @subscription.update(sub_params)
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

  def next
    visit_feed if params[:last_sub]
    cookies[:check_for_updated_subs] = true
    redirect_to current_user.next_feed
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
    params[:subscription][:title] = nil if title&.blank?
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

  def visit_feed
    sub = Subscription.find(params[:last_sub])
    visited_at = Time.at(params[:timestamp].to_i)
    updated = sub.entries.exists?(created_at: visited_at..)
    sub.update(visited_at:, updated:)
  rescue StandardError
    nil
  end
end
