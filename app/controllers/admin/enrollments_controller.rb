class Admin::EnrollmentsController < Admin::BaseController
  def new
    @enrollment = Enrollment.new
    @events = Event.includes(:organization).order(:title)
  end

  def create
    @enrollment = Enrollment.new(enrollment_params)

    if @enrollment.save
      redirect_to admin_dashboard_index_path(tab: "inscripciones"),
                  notice: "Inscripción creada correctamente."
    else
      @events = Event.includes(:organization).order(:title)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def enrollment_params
    params.require(:enrollment).permit(:event_id, :user_id, :status)
  end
end
