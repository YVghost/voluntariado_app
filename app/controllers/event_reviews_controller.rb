class EventReviewsController < ApplicationController
  before_action :set_event
  before_action :authorize_reviewer!

  def new
    @enrollments_to_review = @event.enrollments
                                   .where(status: :asistio)
                                   .includes(:user, :review)
  end

  def create
    reviews_params = params[:reviews] || {}
    errors = []

    reviews_params.each do |enrollment_id, attrs|
      enrollment = @event.enrollments.find_by(id: enrollment_id)
      next unless enrollment

      review = enrollment.review || EnrollmentReview.new(enrollment: enrollment, reviewer: current_user)
      review.assign_attributes(
        primeros_auxilios_score:        attrs[:primeros_auxilios_score].to_i,
        busqueda_rescate_score:         attrs[:busqueda_rescate_score].to_i,
        apoyo_psicosocial_score:        attrs[:apoyo_psicosocial_score].to_i,
        logistica_abastecimiento_score: attrs[:logistica_abastecimiento_score].to_i,
        maquinaria_construccion_score:  attrs[:maquinaria_construccion_score].to_i,
        comment:                        attrs[:comment]
      )
      errors << review.errors.full_messages unless review.save
    end

    if errors.flatten.empty?
      redirect_to @event, notice: "Calificaciones guardadas correctamente."
    else
      @enrollments_to_review = @event.enrollments.where(status: :asistio).includes(:user, :review)
      flash.now[:alert] = "Algunos errores al guardar: #{errors.flatten.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def authorize_reviewer!
    unless current_user.admin? || (current_user.organizador? && @event.organization.user == current_user)
      redirect_to @event, alert: "No tenés permiso para calificar."
    end
  end
end
