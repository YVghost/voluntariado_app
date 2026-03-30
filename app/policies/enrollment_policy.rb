class EnrollmentPolicy < ApplicationPolicy
  def create?  = user.voluntario? || user.admin?
  def destroy? = (user.voluntario? || user.admin?) && record.user == user
end
