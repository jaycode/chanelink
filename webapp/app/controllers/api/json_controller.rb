class Api::JsonController < ApplicationController
  def index
    render :text => 'json!'
  end

end