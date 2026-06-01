class Admin::EventsController < Admin::BaseController
  def new
    @event = Event.new
    authorize @event
  end

  def create
    @event = Event.new(event_params)
    # Admin siempre elige org desde el select; organizer queda forzado a la suya
    @event.organization = current_user.organization if current_user.organizador?
    authorize @event

    if @event.save
      redirect_to admin_dashboard_index_path(tab: "eventos"), notice: "Evento creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def available_volunteers
    event = Event.find(params[:id])
    enrolled_ids = event.enrollments.where.not(status: :cancelado).pluck(:user_id)
    volunteers = User.where(role: :voluntario)
                     .where.not(id: enrolled_ids)
                     .order(:name)
                     .select(:id, :name)
    render json: volunteers.map { |u| { id: u.id, name: u.name } }
  end

  private

  def event_params
    params.expect(event: [:title, :description, :date, :status, :location,
                           :organization_id, :emergency_level, :emergency_type,
                           :min_score, { required_skills: [] }])
  end
end
