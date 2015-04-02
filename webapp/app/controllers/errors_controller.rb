# controller to handle all error related
class ErrorsController < ApplicationController

  layout 'layouts/no_left_menu'
  
  def render_error
    render :template =>'/error/404', :status => 404
  end
end
