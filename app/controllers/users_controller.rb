class UsersController < ApplicationController
  before_action :require_no_authentication, only: %i[new create]
  before_action :logged_in_user, except: %i[new create]
  before_action :correct_user, only: %i[show edit update destroy]

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      redirect_to @user
    else
      render "new"
    end
  end

  def edit
    @user = User.find(params[:id])
    @period_end_message = case [ @user.stripe_subscription_status.present?, @user.cancel_at_period_end? ]
                          when [ true, false ] then "Next billing date:"
                          when [ true, true ] then "Subscription end date:"
                          else "Trial end date:" end
    @expiration_date = @user.expiration_date.to_date.to_formatted_s(:long)
  end

  def update
    user = User.find(params[:id])
    if user.update(user_params)
      user.update_stripe_customer
      flash.now[:success] = "Profile updated."
    end
    render "edit"
  end

  def destroy
    user = User.find(params[:id])
    user.delete_stripe_customer
    user.destroy
    flash[:primary] = "User deleted succesfully."
    redirect_to root_url
  end

  def follow_top_sites
    user = current_user
    Feed.where(top_site: true).shuffle.each do |f|
      user.subscriptions.find_or_create_by(feed: f)
    end
    flash[:primary] = "Ok, done! Happy reading."
    redirect_to user.next_feed
  end

  private

  def update_stripe_customer
    customer_params = { email: params[:email], name: params[:name] }
    Stripe::Customer.update(@user.stripe_customer_id, customer_params)
  end

  def user_params
    params
      .require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  # Confirms the correct user.
  def correct_user
    @user = User.find(params[:id])
    redirect_to root_url unless current_user == @user
  end
end
