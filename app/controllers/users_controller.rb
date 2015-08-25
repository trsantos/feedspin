class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :show, :edit, :update, :destroy]
  before_action :correct_user,   only: [:show, :edit, :update, :destroy]
  before_action :admin_user,     only: [:destroy, :index]

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @topics = Topic.all
  end

  def new
    redirect_to edit_user_path current_user if logged_in?
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    flash[:success] = 'Profile updated.' if @user.update_attributes(user_params)
    render 'edit'
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:info] = 'User deleted.'
    redirect_to users_url
  end

  def update_topics
    @user = User.find(params[:id])
    current_user.topics = []
    # This is REALLY ugly. Will fix ASOP lol.
    # I need to do the unfollowing first so that
    # feeds are not unsubscribed by accident
    params[:topic].each do |t, v|
      t = Topic.find_by(name: t)
      current_user.unfollow_topic(t) if v == '0'
    end
    params[:topic].each do |t, v|
      t = Topic.find_by(name: t)
      current_user.follow_topic(t) if v == '1'
    end
    flash[:info] = 'Topics updated. Happy reading!'
    redirect_to next_path
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password,
                                 :password_confirmation)
  end

  # Confirms a logged-in user.
  def logged_in_user
    return if logged_in?
    store_location
    flash[:alert] = 'Please log in.'
    redirect_to login_url
  end

  # Confirms the correct user.
  def correct_user
    @user = User.find(params[:id])
    redirect_to edit_user_path current_user unless current_user?(@user)
  end

  # Confirms an admin user.
  def admin_user
    redirect_to(root_url) unless current_user.admin?
  end
end
