class EnrollmentsController < ApplicationController
  before_action :set_event

  def create
    @enrollment = @event.enrollments.new(user: current_user)
    authorize @enrollment

    if @enrollment.save
      redirect_to @event, notice: "Te inscribiste correctamente."
    else
      redirect_to @event, alert: @enrollment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @enrollment = @event.enrollments.find_by!(user: current_user)
    authorize @enrollment
    @enrollment.cancelado!
    redirect_to @event, notice: "Inscripción cancelada."
  end

  def check_in
    @enrollment = @event.enrollments.find_by!(user: current_user)
    authorize @enrollment, :update?

    @enrollment.update!(
      status: :asistio,
      check_in_time: Time.current,
      latitude: params[:latitude],
      longitude: params[:longitude]
    )

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "enrollment_section",
          partial: "events/enrollment_section",
          locals: { event: @event, enrollment: @enrollment }
        )
      }
      format.html { redirect_to @event, notice: "¡Check-in realizado!" }
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
