class NotificationService
  def self.event_finalizado(event)
    event.enrollments.where.not(status: :cancelado).each do |enrollment|
      create_for(enrollment, "El evento \"#{event.title}\" ha finalizado.", notifiable: event)
    end
  end

  def self.inscripcion_confirmada(enrollment)
    create_for(enrollment, "Te inscribiste correctamente en \"#{enrollment.event.title}\".")
  end

  def self.voluntario_convocado(enrollment)
    event = enrollment.event
    create_for(enrollment, "Fuiste convocado para la emergencia \"#{event.title}\" (T#{event.emergency_level}). Confirmá tu asistencia.")
  end

  def self.convocado_con_conflicto(enrollment, message)
    create_for(enrollment, message)
  end

  def self.segunda_ola(enrollment, message)
    create_for(enrollment, message)
  end
 
  private_class_method def self.create_for(enrollment, message, notifiable: enrollment)
    Notification.create!(user: enrollment.user, notifiable: notifiable, message: message)
  end
end
