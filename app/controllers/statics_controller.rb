class StaticsController < ApplicationController
  before_filter :authenticate_user!, only: [:dashboard]
  doorkeeper_for :me

  def me
    render json: current_resource_owner
  end

  protected
  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end
end
