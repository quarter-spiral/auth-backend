require 'uri'
class ApplicationController < ActionController::Base
  protect_from_forgery

  protected
  alias raw_after_sign_in_path_for after_sign_in_path_for
  def after_sign_in_path_for(resource_or_scope)
    redirect_url = raw_after_sign_in_path_for(resource_or_scope)

    params_url = params[:redirect_uri]
    referer_url = request.env['HTTP_REFERER']

    if params_url && request.host == URI.parse(params_url).host
      redirect_url = params_url
    elsif referer_url && request.host == URI.parse(referer_url).host
      redirect_url = referer_url
    end

    redirect_url
  end

  def after_sign_out_path_for(resource_or_scope)
    redirect_url_by_params(root_path)
  end

  def redirect_url_by_params(redirect_url)
    if params[:redirect_uri] && Doorkeeper::Application.where(['redirect_uri LIKE ?', "#{params[:redirect_uri]}%"]).first
      redirect_url = params[:redirect_uri]
    end

    redirect_url
  end
end
