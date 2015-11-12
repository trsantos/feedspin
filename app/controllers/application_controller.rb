class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper

  # Confirms a logged-in user.
  def logged_in_user
    return if logged_in?
    store_location
    flash[:alert] = 'Please log in.'
    redirect_to login_url
  end

  def expiration_date_presence
    user = current_user
    return unless user.expiration_date.nil?
    user.update_attribute(:expiration_date, 2.weeks.from_now)
  end
end
