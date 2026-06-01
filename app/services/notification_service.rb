class NotificationService
  def self.event_finalizado(event)
    event.enrollments.where.not(status: :cancelado).each do |enrollment|
      Notification.create!(
        user:       enrollment.user,
        notifiable: event,
        message:    "El evento \"#{event.title}\" ha finalizado."
      )
    end
  end

  def self.inscripcion_confirmada(enrollment)
    Notification.create!(
      user:       enrollment.user,
      notifiable: enrollment,
      message:    "Te inscribiste correctamente en \"#{enrollment.event.title}\"."
    )
  end

  def self.voluntario_convocado(enrollment)
    event = enrollment.event
    Notification.create!(
      user:       enrollment.user,
      notifiable: enrollment,
      message:    "Fuiste convocado para la emergencia \"#{event.title}\" (T#{event.emergency_level}). Confirmá tu asistencia."
    )
  end

  def self.convocado_con_conflicto(enrollment, message)
    Notification.create!(
      user:       enrollment.user,
      notifiable: enrollment,
      message:    message
    )
  end

  def self.segunda_ola(enrollment, message)
    Notification.create!(
      user:       enrollment.user,
      notifiable: enrollment,
      message:    message
    )
  end
end
