class FeedsController < ApplicationController
  skip_before_filter :authenticate

  def personal
    user = Person.find_by_stringid params[:person]
    if user.nil?
      render :template => 'error.html.erb', :status => 404
      return
    end

    @items = user.starship_messages.find :all, :limit => 100, :order => "created desc"
  end
end
