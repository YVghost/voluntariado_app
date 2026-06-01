class EmergencyConflictResolver
  Result = Struct.new(:action, :message, keyword_init: true)

  # action values: :convoke | :convoke_conflict | :second_wave | :skip

  def initialize(new_event, profile)
    @new_event = new_event
    @profile   = profile
  end

  def resolve
    resolution = @profile.conflict_resolution_for(@new_event)
    Result.new(action: resolution, message: message_for(resolution))
  end

  private

  def message_for(action)
    event = @new_event
    case action
    when :convoke
      nil
    when :convoke_conflict
      current = current_emergency_title
      "Fuiste convocado para \"#{event.title}\" (T#{event.emergency_level}), que tiene mayor prioridad que tu emergencia actual \"#{current}\". Revisá ambas y coordiná con los organizadores."
    when :second_wave
      arrival = SECOND_WAVE_DAYS.days.from_now
      country = event.country_from_location
      "Se necesita apoyo en #{country} para \"#{event.title}\" (T#{event.emergency_level}). Tiempo estimado de llegada: #{arrival.strftime('%d/%m/%Y')} (#{SECOND_WAVE_DAYS} días). ¿Confirmás disponibilidad para viajar?"
    when :skip
      nil
    end
  end

  def current_emergency_title
    enrollment = @profile.user.enrollments
                          .joins(:event)
                          .where.not(events: { emergency_level: nil })
                          .where(events: { status: [:activo, :en_curso] })
                          .where(status: [:convocado, :confirmado])
                          .where.not(event: @new_event)
                          .order("events.emergency_level DESC")
                          .first
    enrollment&.event&.title || "otra emergencia"
  end

  SECOND_WAVE_DAYS = VolunteerProfile::SECOND_WAVE_DAYS
end
