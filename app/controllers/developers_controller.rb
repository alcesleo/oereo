class DevelopersController < ApplicationController

  def index
    if current_developer
      @access_token = current_developer.access_token
    end
  end

  def new
    @developer = Developer.new
  end

  def create
    @developer = Developer.new(developer_params)
    if @developer.save
      redirect_to root_url, flash: { success: 'Successfully registered.' }
    else
      render 'new'
    end
  end

private
  def developer_params
    params.require(:developer).permit(:email, :password, :password_confirmation)
  end
end
