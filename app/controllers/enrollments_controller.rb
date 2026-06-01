class EnrollmentsController < ApplicationController
  before_action :set_event

  def create
    @enrollment = @event.enrollments.new(user: current_user, status: :confirmado)
    authorize @enrollment

    if @enrollment.save
      redirect_to @event, notice: "Te inscribiste correctamente."
    else
      redirect_to @event, alert: @enrollment.errors.full_messages.to_sentence
    end
  end

  def update
    @enrollment = @event.enrollments.find_by!(user: current_user)
    authorize @enrollment
    @enrollment.update!(status: params.dig(:enrollment, :status))
    redirect_to @event, notice: "Inscripción actualizada."
  end

  def destroy
    @enrollment = @event.enrollments.find_by!(user: current_user)
    authorize @enrollment
    @enrollment.cancelado!
    redirect_to @event, notice: "Inscripción cancelada."
  end

  def mark_attendance
    @enrollment = @event.enrollments.find(params[:id])
    authorize @enrollment, :mark_attendance?
    @enrollment.update!(status: :asistio, attended_at: Time.current)
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "enrollment_#{@enrollment.id}",
          partial: "enrollments/enrollment",
          locals: { enrollment: @enrollment, event: @event }
        )
      }
      format.html { redirect_to @event, notice: "Asistencia marcada." }
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
