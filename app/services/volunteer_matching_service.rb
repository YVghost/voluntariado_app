class VolunteerMatchingService
  MAX_IMMEDIATE   = 20
  MAX_SUPPORT     = 50

  def initialize(event)
    @event = event
  end

  def call
    return unless @event.emergency_level.present?

    immediate = []
    support   = []

    candidate_profiles.each do |profile|
      tier = profile.tier_for_event(@event)
      next unless tier

      if profile.busy_in_active_emergency?(exclude_event: @event)
        resolver = EmergencyConflictResolver.new(@event, profile)
        result   = resolver.resolve

        case result.action
        when :convoke_conflict
          convoke!(profile, second_wave: false, conflict_message: result.message)
        when :second_wave
          convoke_second_wave!(profile, result.message)
        when :skip, :convoke
          # :skip → no convocar; :convoke nunca ocurre aquí (busy devolvió true)
          next if result.action == :skip
        end
      else
        case tier
        when :immediate then immediate << profile
        when :support   then support   << profile
        end
      end
    end

    immediate.sort_by { |p| -p.score }.first(MAX_IMMEDIATE).each { |p| convoke!(p) }
    support.sort_by   { |p| -p.score }.first(MAX_SUPPORT).each   { |p| convoke!(p) }
  end

  private

  def candidate_profiles
    VolunteerProfile
      .includes(:user)
      .where(available: true)
      .where.not(quiz_completed_at: nil)
  end

  def convoke!(profile, second_wave: false, conflict_message: nil)
    return if @event.enrollments.exists?(user: profile.user)

    enrollment = @event.enrollments.create!(
      user:        profile.user,
      status:      :convocado,
      second_wave: second_wave
    )

    if second_wave
      NotificationService.voluntario_convocado(enrollment)
    elsif conflict_message.present?
      NotificationService.convocado_con_conflicto(enrollment, conflict_message)
    else
      NotificationService.voluntario_convocado(enrollment)
    end
  end

  def convoke_second_wave!(profile, message)
    return if @event.enrollments.exists?(user: profile.user)

    arrival = VolunteerProfile::SECOND_WAVE_DAYS.days.from_now
    enrollment = @event.enrollments.create!(
      user:             profile.user,
      status:           :convocado,
      second_wave:      true,
      expected_arrival: arrival
    )

    NotificationService.segunda_ola(enrollment, message)
  end
end
