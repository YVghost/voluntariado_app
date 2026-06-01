class EventPolicy < ApplicationPolicy
  # Voluntarios solo ven eventos activos; organizadores ven los suyos; admin ve todo
  def index? = true

  # Voluntarios pueden ver eventos vigentes (activo o en_curso); no los finalizados
  def show?
    user.admin? ||
      (user.organizador? && own_event?) ||
      (user.voluntario? && (record.activo? || record.en_curso?))
  end

  # Solo admin y organizador pueden crear
  def create? = user.admin? || user.organizador?

  # Organizador solo edita/finaliza/elimina sus propios eventos
  def update?  = user.admin? || (user.organizador? && own_event?)
  def destroy? = user.admin? || (user.organizador? && own_event?)

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.organizador?
        # Solo los eventos de su organización
        scope.joins(:organization).where(organizations: { user_id: user.id })
      else
        # Voluntarios: eventos vigentes (activo + en_curso)
        scope.vigentes
      end
    end
  end

  private

  def own_event?
    record.organization.user == user
  end
end
