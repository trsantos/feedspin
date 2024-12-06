class PaymentsController < ApplicationController
  include PaymentsHelper

  skip_before_action :verify_authenticity_token, only: [:webhook]
  before_action :logged_in_user, except: [:webhook]

  def new
    redirect_to billing_portal_url if current_user.stripe_subscription_status.present?
    @user = current_user
    @price = Payment.monthly_price
  end

  def create
    create_stripe_customer if current_user.stripe_customer_id.nil?
    session_data = build_session_data
    session = Stripe::Checkout::Session.create(session_data)
    redirect_to session.url, allow_other_host: true
  end

  def success
    fulfill_checkout(params[:session_id])
    flash[:success] = 'Thank you for subscribing to FeedSpin!'
    redirect_to root_url
  end

  def billing_portal
    session_data = {
      customer: current_user.stripe_customer_id,
      return_url: edit_user_url(current_user)
    }
    session = Stripe::BillingPortal::Session.create(session_data)
    redirect_to session.url, allow_other_host: true
  end

  def webhook
    event = Stripe::Event.retrieve(params[:id])
    case event.type
    when 'customer.subscription.created',
         'customer.subscription.updated'
      update_subscription event.data.object.id
    when 'customer.subscription.deleted'
      delete_subscription event.data.object.id
    when 'customer.deleted'
      delete_customer event.data.object.id
    end
  end

  private

  def delete_customer(customer_id)
    user_params = {
      cancel_at_period_end: false,
      stripe_customer_id: nil,
      stripe_subscription_status: nil
    }
    User.where(stripe_customer_id: customer_id).update_all(user_params)
  end

  def update_subscription(subscription_id)
    subscription = Stripe::Subscription.retrieve(subscription_id)
    user_params = {
      cancel_at_period_end: subscription.cancel_at_period_end,
      expiration_date: Time.at(subscription.current_period_end),
      stripe_subscription_status: subscription.status
    }
    User.find_by(stripe_customer_id: subscription.customer)&.update(user_params)
  end

  def delete_subscription(subscription_id)
    subscription = Stripe::Subscription.retrieve(subscription_id)
    user_params = { cancel_at_period_end: false, stripe_subscription_status: nil }
    User.find_by(stripe_customer_id: subscription.customer)&.update(user_params)
  end

  def fulfill_checkout(session_id)
    session = Stripe::Checkout::Session.retrieve(session_id)
    update_subscription session.subscription
  end

  def create_stripe_customer
    customer   = Stripe::Customer.list(email: current_user.email, limit: 1).data.first
    customer ||= Stripe::Customer.create(email: current_user.email, name: current_user.name)
    current_user.update(stripe_customer_id: customer.id)
  end

  def build_session_data
    price = fetch_stripe_price
    subscription_data = build_subscription_data
    {
      cancel_url: new_payment_url,
      customer: current_user.stripe_customer_id,
      line_items: [{ price: price.id, quantity: 1 }],
      mode: 'subscription',
      subscription_data:,
      success_url: CGI.unescape(success_checkout_url(session_id: '{CHECKOUT_SESSION_ID}'))
    }
  end

  def fetch_stripe_price
    Stripe::Price.list(lookup_keys: ['feedspin_monthly']).data.first
  end

  def build_subscription_data
    trial_diff = current_user.expiration_date - Time.current
    trial_period_days = trial_diff.seconds.in_days.ceil
    { trial_period_days: } if trial_period_days.positive?
  end
end
