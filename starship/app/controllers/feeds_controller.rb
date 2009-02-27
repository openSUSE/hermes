class FeedsController < ApplicationController
  def personal
    user = Person.find_by_stringid params[:person]
    if user.nil?
      render :template => 'error.html.erb', :status => 404
      return
    end

    @items = StarshipMessage.find :all, :limit => 10
  end
end
