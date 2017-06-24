class ChargesController < ApplicationController
  before_action :authenticate_user!

  def new
   @stripe_btn_data = {
     key: "#{ Rails.configuration.stripe[:publishable_key] }",
     description: "Premium Membership - #{current_user.email}",
     amount: 1500
   }
  end

  def create
  customer = Stripe::Customer.create(
    email: current_user.email,
    card: params[:stripeToken]
  )

  subscription = Stripe::Subscription.create(
    customer: customer.id,
    plan: 'premium',
  )

  current_user.update_attributes(role: 'premium')
  current_user.update_attributes(stripe_id: customer.id)
  current_user.update_attributes(stripe_subscription: subscription.id)

  flash[:notice] = "Your payment was successfully submitted, #{current_user.email}. Welcome to premium!"
  redirect_to wikis_path

  rescue Stripe::CardError => e
    flash[:alert] = e.message
    redirect_to new_charge_path
  end

  def destroy
    subscription = Stripe::Subscription.retrieve(current_user.stripe_subscription)
    subscription.delete
    current_user.update_attributes(role: 'standard')
    redirect_to root_path
    flash[:notice] = "Your membership has been downgraded to standard."
  end
end