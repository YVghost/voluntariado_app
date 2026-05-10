class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    if user_signed_in?
      redirect_to events_path
    else
      @eventos_count = Event.count
      @organizaciones_count = Organization.count
      @voluntarios_count = User.where(role: :voluntario).count
    end
  end
end