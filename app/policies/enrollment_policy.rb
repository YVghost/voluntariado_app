class EnrollmentPolicy < ApplicationPolicy
  def create?
    return false unless user.voluntario?
    return false unless record.event.activo? || record.event.en_curso?

    profile = user.volunteer_profile
    return false unless profile&.quiz_completed_at.present?

    # Debe tener al menos tier :support para esta emergencia
    # (o no ser una emergencia — evento normal, libre inscripción)
    if record.event.emergency_level.present?
      tier = profile.tier_for_event(record.event)
      return false unless tier  # nil = bloqueado
    end

    true
  end

  def destroy?
    user.voluntario? && record.user == user
  end

  def update?
    user.voluntario? && record.user == user && record.event.activo?
  end

  def mark_attendance?
    (user.organizador? && record.event.organization.user == user) || user.admin?
  end
end
