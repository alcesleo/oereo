class ResourcesController < ApplicationController

  respond_to :json

  before_filter :restrict_access

  def index
    respond_with Resource.all
  end

  def show
    respond_with Resource.find(params[:id])
  end

  def create
    respond_with Resource.create(params[:resource])
  end

  def update
    respond_with Resource.update(params[:id], params[:resource])
  end

  def destroy
    respond_with Resource.destroy(params[:id])
  end

  private
  def restrict_access
    api_key = ApiKey.find_by_access_token(params[:access_token])
    head :unauthorized unless api_key
  end

end
