class VolunteerProfile < ApplicationRecord
  belongs_to :user

  SKILLS = %w[
    primeros_auxilios
    busqueda_rescate
    apoyo_psicosocial
    logistica_abastecimiento
    maquinaria_construccion
  ].freeze

  SKILL_LABELS = {
    "primeros_auxilios"        => "Primeros Auxilios",
    "busqueda_rescate"         => "Búsqueda y Rescate",
    "apoyo_psicosocial"        => "Apoyo Psicosocial",
    "logistica_abastecimiento" => "Logística y Abastecimiento",
    "maquinaria_construccion"  => "Maquinaria / Construcción"
  }.freeze

  CERTIFICATIONS = {
    "cert_primeros_auxilios" => { label: "Primeros Auxilios certificado (Cruz Roja / Defensa Civil)", points: 1.0 },
    "cert_rescate"           => { label: "Rescate en espacios confinados o altura",                  points: 1.5 },
    "cert_pap"               => { label: "Primeros Auxilios Psicológicos (PAP)",                     points: 1.0 },
    "cert_conduccion"        => { label: "Licencia de conducción tipo C o D",                        points: 0.5 },
    "cert_maquinaria"        => { label: "Operador de maquinaria pesada certificado",                points: 2.0 },
    "cert_construccion"      => { label: "Técnico o ingeniero civil / construcción",                 points: 1.5 },
    "cert_enfermeria"        => { label: "Técnico en enfermería o paramédico",                       points: 2.0 },
    "cert_bombero"           => { label: "Formación como bombero voluntario",                        points: 2.0 }
  }.freeze

  LEVEL_WEIGHTS = {
    "primeros_auxilios"        => 1.2,
    "busqueda_rescate"         => 1.5,
    "apoyo_psicosocial"        => 0.8,
    "logistica_abastecimiento" => 0.9,
    "maquinaria_construccion"  => 1.3
  }.freeze

  # Umbrales de score_por_skill (escala 0–4) para ser convocado por nivel de emergencia
  SKILL_IMMEDIATE_THRESHOLD = { 1 => 1.5, 2 => 2.0, 3 => 2.5, 4 => 3.0, 5 => 3.2, 6 => 3.5 }.freeze
  SKILL_SUPPORT_THRESHOLD   = { 1 => 0.5, 2 => 1.0, 3 => 1.5, 4 => 2.0, 5 => 2.5, 6 => 3.0 }.freeze

  # Umbrales globales (fallback cuando el evento no tiene required_skills)
  IMMEDIATE_THRESHOLD = { 1 => 4.0, 2 => 5.0, 3 => 5.5, 4 => 6.5, 5 => 7.0, 6 => 8.0 }.freeze
  SUPPORT_THRESHOLD   = { 1 => 2.0, 2 => 3.0, 3 => 4.0, 4 => 5.0, 5 => 6.0, 6 => 7.0 }.freeze

  # Duración estimada por nivel (en horas), usada para detectar cruces de tiempo
  ASSUMED_DURATION_HOURS = { 1 => 4, 2 => 6, 3 => 12, 4 => 24, 5 => 48, 6 => 72 }.freeze

  SECOND_WAVE_DAYS = 7

  SECTION_MAP = {
    "primeros_auxilios"        => %w[q1 q2 q3 q4 q5],
    "busqueda_rescate"         => %w[q6 q7 q8 q9 q10],
    "apoyo_psicosocial"        => %w[q11 q12 q13 q14 q15],
    "logistica_abastecimiento" => %w[q16 q17 q18 q19 q20],
    "maquinaria_construccion"  => %w[q21 q22 q23 q24 q25]
  }.freeze

  # ─────────────────────────────────────────────
  # Cálculo de score desde quiz
  # ─────────────────────────────────────────────

  def calculate_score!
    return unless quiz_answers.present?

    raw_scores  = {}
    new_skill_scores = {}
    active_skills = []

    SECTION_MAP.each do |section, questions|
      total = questions.sum { |q| quiz_answers[q].to_i }
      max   = questions.size * 4
      pct   = total.to_f / max           # 0.0..1.0
      raw_scores[section]       = pct
      new_skill_scores[section] = (pct * 4).round(2)  # escala 0–4
      active_skills << section if pct >= 0.25
    end
   ### formula de calculo de score 
   ### base_score = (Σ (pct_sección × peso) / Σ pesos) × 10
    weight_sum = LEVEL_WEIGHTS.values.sum
    weighted   = raw_scores.sum { |section, pct| pct * LEVEL_WEIGHTS[section] }
    base_score = (weighted / weight_sum) * 10.0

    cert_bonus = certifications.sum { |key, val|
      val.to_s == "1" ? (CERTIFICATIONS[key]&.dig(:points) || 0) : 0
    }
    final_score = [base_score + cert_bonus, 10.0].min.round(2)

    # Si ya hay skill_scores de reviews, mezclamos: 40% quiz + 60% reviews
    merged = new_skill_scores.merge(skill_scores || {}) { |_skill, quiz_val, review_val|
      ((quiz_val * 0.4) + (review_val.to_f * 0.6)).round(2)
    }

    update!(
      score:            final_score,
      skills:           active_skills,
      skill_scores:     merged,
      quiz_completed_at: Time.current
    )
  end

  # ─────────────────────────────────────────────
  # Actualización desde calificaciones de eventos
  # ─────────────────────────────────────────────

  def update_skills_from_reviews!
    reviews = EnrollmentReview.joins(:enrollment).where(enrollments: { user_id: user_id })
    return if reviews.empty?

    # ── 1. Score del quiz calculado SIEMPRE desde quiz_answers originales ──
    # (evita compounding: nunca usamos skill_scores almacenados como base)
    quiz_raw = {}
    if quiz_answers.present?
      SECTION_MAP.each do |skill, questions|
        total = questions.sum { |q| quiz_answers[q].to_i }
        quiz_raw[skill] = (total.to_f / (questions.size * 4) * 4).round(2)  # escala 0–4
      end
    end

    # ── 2. Promedio de reviews por skill — incluye ceros (0 = "No aplicó") ──
    review_avgs = {}
    SKILLS.each do |skill|
      scores = reviews.map(&:"#{skill}_score").compact
      next if scores.empty?
      review_avgs[skill] = (scores.sum.to_f / scores.size).round(2)
    end

    return if review_avgs.empty?

    # ── 3. Mezcla limpia: 40% quiz_raw + 60% promedio reviews ──
    merged = SKILLS.each_with_object({}) do |skill, h|
      q = quiz_raw[skill].to_f
      r = review_avgs[skill]
      h[skill] = r ? ((q * 0.4) + (r * 0.6)).round(2) : q
    end

    updated_skills = SKILLS.select { |s| merged[s].to_f >= 1.0 }

    # ── 4. Score global desde skill_scores mezclados ──
    weight_sum = LEVEL_WEIGHTS.values.sum
    weighted   = merged.sum { |skill, val| (val.to_f / 4.0) * LEVEL_WEIGHTS[skill].to_f }
    base_score = (weighted / weight_sum) * 10.0

    # ── 5. Bonus certs proporcional al máximo posible, tope 2.0 puntos ──
    # (evita que acumulación de certs anule el efecto de las calificaciones)
    raw_cert  = certifications.to_h.sum { |k, v| v.to_s == "1" ? (CERTIFICATIONS[k]&.dig(:points) || 0) : 0 }
    max_cert  = CERTIFICATIONS.values.sum { |v| v[:points] }
    cert_bonus = max_cert > 0 ? (raw_cert.to_f / max_cert * 2.0).round(2) : 0.0

    new_score = [base_score + cert_bonus, 10.0].min.round(2)

    update_columns(score: new_score, skill_scores: merged, skills: updated_skills)
  end
 
  # ─────────────────────────────────────────────
  # Tier del voluntario para un evento específico
  # Retorna :immediate, :support, o nil
  # ─────────────────────────────────────────────

  def tier_for_event(event)
    return nil unless available? && quiz_completed_at.present?
    return nil unless event.emergency_level.present?

    level    = event.emergency_level.to_i
    required = Array(event.required_skills).compact.reject(&:empty?)

    if required.any?
      skill_tier_for(required, level)
    else
      global_tier_for(level)
    end
  end

  # ─────────────────────────────────────────────
  # Verifica si el voluntario ya está activo en
  # otra emergencia (para el check de disponibilidad)
  # ─────────────────────────────────────────────

  def busy_in_active_emergency?(exclude_event: nil)
    scope = user.enrollments
                .joins(:event)
                .where.not(events: { emergency_level: nil })
                .where(events: { status: [:activo, :en_curso] })
                .where(status: [:convocado, :confirmado])
    scope = scope.where.not(event: exclude_event) if exclude_event
    scope.exists?
  end

  # ─────────────────────────────────────────────
  # Resolución de conflicto con otra emergencia.
  # Retorna uno de:
  #   :convoke          – sin conflicto, convocar normalmente
  #   :convoke_conflict – hay cruce pero nueva tiene mayor prioridad
  #   :second_wave      – evento en otro país
  #   :skip             – emergencia actual tiene prioridad, no convocar
  # ─────────────────────────────────────────────

  def conflict_resolution_for(new_event)
    active_enrollment = user.enrollments
                            .joins(:event)
                            .where.not(events: { emergency_level: nil })
                            .where(events: { status: [:activo, :en_curso] })
                            .where(status: [:convocado, :confirmado])
                            .where.not(event: new_event)
                            .order("events.emergency_level DESC")
                            .first

    return :convoke unless active_enrollment

    current_event = active_enrollment.event

    # Comparación 3: país diferente → segunda ola
    new_country     = new_event.country_from_location
    current_country = current_event.country_from_location
    volunteer_country = country

    if new_country.present? && volunteer_country.present? && new_country != volunteer_country
      return :second_wave
    end

    # Comparación 2: cruce de tiempos
    return :convoke unless times_overlap?(current_event, new_event)

    # Comparación 1: prioridad por nivel
    level_diff = new_event.emergency_level.to_i - current_event.emergency_level.to_i

    if level_diff >= 2
      :convoke_conflict  # nueva es significativamente más urgente
    elsif level_diff == 1
      :convoke_conflict  # nueva tiene algo más de prioridad
    else
      :skip              # igual o menor prioridad, se mantiene en la actual
    end
  end

  # ─────────────────────────────────────────────
  # Fallback legacy (usado en vistas de index)
  # ─────────────────────────────────────────────

  def call_level_for(emergency_level)
    return nil unless emergency_level.present? && available?
    level = emergency_level.to_i
    if score >= IMMEDIATE_THRESHOLD[level].to_f
      :immediate
    elsif score >= SUPPORT_THRESHOLD[level].to_f
      :support
    else
      nil
    end
  end

  private

  def skill_tier_for(required_skills, level)
    scores = skill_scores.presence

    # Sin skill_scores todavía (perfil viejo o recién creado) → usa score global
    return global_tier_for(level) if scores.blank?

    imm_threshold = SKILL_IMMEDIATE_THRESHOLD[level]
    sup_threshold = SKILL_SUPPORT_THRESHOLD[level]

    skill_results = required_skills.map { |s| scores[s].to_f }

    if skill_results.all? { |s| s >= imm_threshold }
      :immediate
    elsif skill_results.any? { |s| s >= sup_threshold }
      :support
    else
      nil
    end
  end

  def global_tier_for(level)
    if score >= IMMEDIATE_THRESHOLD[level].to_f
      :immediate
    elsif score >= SUPPORT_THRESHOLD[level].to_f
      :support
    else
      nil
    end
  end

  def times_overlap?(event_a, event_b)
    return false unless event_a.date.present? && event_b.date.present?

    dur_a = ASSUMED_DURATION_HOURS[event_a.emergency_level.to_i].to_i.hours
    dur_b = ASSUMED_DURATION_HOURS[event_b.emergency_level.to_i].to_i.hours

    start_a = event_a.date
    end_a   = start_a + dur_a
    start_b = event_b.date
    end_b   = start_b + dur_b

    start_a < end_b && start_b < end_a
  end
end
