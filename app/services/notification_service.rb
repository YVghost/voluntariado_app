class NotificationService
  # Notifica a todos los voluntarios inscritos cuando un evento se finaliza
  def self.event_finalizado(event)
    event.enrollments.where.not(status: :cancelado).each do |enrollment|
      Notification.create!(
        user: enrollment.user,
        notifiable: event,
        message: "El evento \"#{event.title}\" ha finalizado."
      )
    end
  end

  # Notifica al voluntario cuando su inscripción es confirmada
  def self.inscripcion_confirmada(enrollment)
    Notification.create!(
      user: enrollment.user,
      notifiable: enrollment,
      message: "Te inscribiste correctamente en \"#{enrollment.event.title}\"."
    )
  end
end
