class Admin::Doorkeeper::ApplicationsController < Admin::ResourcesController
  def create
    params[:doorkeeper_application] = params.delete(:application)
    super
  end
  
  def update
    params[:doorkeeper_application] = params.delete(:application)
    super
  end
end
