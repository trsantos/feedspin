class FeedsController < ApplicationController
  include ApplicationHelper

  before_action :logged_in_user
  before_action :set_user
  before_action :check_expiration_date
  before_action :set_subscription, only: [:show]
  before_action :unread_feeds, only: [:show]

  after_action :update_feeds, only: [:show]

  def show
    cookies.delete :check_for_updated_subs
    @feed = Feed.find(params[:id])
    return if @feed.fetching

    @entries = @feed.entries.order(pub_date: :desc).page(params[:page]).per(10)
    @image_only_feed = @entries.all? { |e| !e.has_text? }
  end

  def new
    if params[:feed_url].present?
      feed = find_or_create_feed(params[:feed_url])
      redirect_to feed
    else
      @feed = Feed.new
    end
  end

  def create
    feed = find_or_create_feed(params[:feed][:feed_url])
    redirect_to feed
  end

  private

  def find_or_create_feed(url)
    Feed.find_or_create_by(feed_url: process_url(url))
  end

  def set_user
    @user = current_user
    @user.touch
  end

  def check_expiration_date
    return if @user.stripe_subscription_status.in? %w[active trialing]
    return if Time.current <= @user.expiration_date

    redirect_to new_payment_path
  end

  def set_subscription
    @subscription = @user.subscriptions.find_by(feed_id: params[:id])
  end

  def unread_feeds
    return unless @subscription
    return unless cookies[:check_for_updated_subs]
    return if @user.subscriptions.exists?(updated: true)

    flash.now[:primary] = 'You have no updated feeds right now. Check back later!'
  end

  def update_feeds
    @user.update_feeds
  end
end
