class OrganizationPolicy < ApplicationPolicy
  # Todos pueden ver el listado y el detalle
  def index? = true
  def show?  = true

  # Solo admin puede crear organizaciones (se crean al registrarse como organización)
  def create?  = user.admin?

  # Organizador solo puede editar/eliminar la suya propia; admin todo
  def update?  = user.admin? || (user.organizador? && record.user == user)
  def destroy? = user.admin? || (user.organizador? && record.user == user)

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
