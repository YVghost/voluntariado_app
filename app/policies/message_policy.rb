class MessagePolicy < ApplicationPolicy
  # Cualquier usuario autenticado puede enviar mensajes
  def create? = true
end
