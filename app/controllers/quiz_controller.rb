class QuizController < ApplicationController
  before_action :authenticate_user!
  before_action :require_volunteer!

  def show
    @profile = current_user.volunteer_profile || current_user.build_volunteer_profile
  end

  def update
    @profile = current_user.volunteer_profile || current_user.build_volunteer_profile

    if @profile.quiz_completed_at.present?
      return redirect_to quiz_path, alert: "El cuestionario ya fue completado y no puede modificarse."
    end

    quiz_answers = params[:quiz]&.permit!.to_h || {}
    certifications = params[:certifications]&.permit!.to_h || {}
    profile_location = params.permit(:country, :city, :sector).to_h

    @profile.assign_attributes(
      quiz_answers:   quiz_answers,
      certifications: certifications
    )
    @profile.assign_attributes(profile_location)
    @profile.save!
    @profile.calculate_score!

    redirect_to quiz_path, notice: "Perfil completado. Tus habilidades se actualizan con cada participación."
  rescue ActiveRecord::RecordInvalid => e
    @profile.errors.add(:base, e.message)
    render :show, status: :unprocessable_entity
  end

  def toggle_availability
    profile = current_user.volunteer_profile
    return redirect_to root_path, alert: "Completá tu perfil primero." unless profile
    profile.update!(available: !profile.available)
    msg = profile.available? ? "Estás disponible para emergencias." : "Pausaste tu disponibilidad."
    redirect_back fallback_location: root_path, notice: msg
  end

  private

  def require_volunteer!
    unless current_user.voluntario?
      redirect_to root_path, alert: "Solo los voluntarios pueden acceder a esta sección."
    end
  end
end
