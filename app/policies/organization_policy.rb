class OrganizationPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true

  def create?  = user.admin? || user.organizador?
  def update?  = user.admin? || user.organizador?
  def destroy? = user.admin? || user.organizador?
end
