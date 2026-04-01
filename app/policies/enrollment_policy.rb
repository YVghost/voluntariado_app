class EnrollmentPolicy < ApplicationPolicy
  # Solo voluntarios pueden inscribirse, y solo en eventos activos
  def create?
    user.voluntario? && record.event.activo?
  end

  # Solo el propio voluntario puede cancelar su inscripción
  def destroy?
    user.voluntario? && record.user == user
  end

  # Check-in: mismo voluntario, evento activo
  def update?
    user.voluntario? && record.user == user && record.event.activo?
  end
end
