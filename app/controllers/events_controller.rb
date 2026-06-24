class EventsController < ApplicationController
  before_action :set_event, only: %i[ show edit update destroy iniciar finalizar ]
  before_action :auto_cancelar_expirados, only: %i[ index show ]

  def index
    @events = policy_scope(Event)
    authorize Event

    if current_user&.voluntario? && current_user.profile_complete?
      profile = current_user.volunteer_profile

      convocado_enrollments = current_user.enrollments
                                          .joins(:event)
                                          .where(status: :convocado)
                                          .where(events: { status: [:activo, :en_curso] })

      @convocados   = Event.where(id: convocado_enrollments.where(second_wave: false).select(:event_id))
      @segunda_ola  = Event.where(id: convocado_enrollments.where(second_wave: true).select(:event_id))

      enrolled_ids  = current_user.events.pluck(:id)
      @disponibles  = Event.vigentes
                           .where.not(id: enrolled_ids)
                           .where.not(emergency_level: nil)
                           .select { |e| profile.tier_for_event(e) == :support }
                           .first(10)
    end
  end

  def show
    authorize @event
  end

  def new
    @event = Event.new
    # Pre-asignar la organización del organizador actual
    if current_user.organizador? && current_user.organization.present?
      @event.organization = current_user.organization
    end
    authorize @event
  end

  def edit
    authorize @event
  end

  def create
    @event = Event.new(event_params)
    force_organization!(@event)
    authorize @event

    if @event.save
      redirect_to @event, notice: "Evento creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @event
    force_organization!(@event)

    if @event.update(event_params)
      redirect_to @event, notice: "Evento actualizado correctamente.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @event
    @event.destroy!
    redirect_to events_path, notice: "Evento eliminado.", status: :see_other
  end

  def iniciar
    authorize @event, :update?
    if @event.activo?
      @event.en_curso!
      redirect_to @event, notice: "Evento iniciado. Podés empezar a marcar asistencia.", status: :see_other
    else
      redirect_to @event, alert: "El evento no puede iniciarse en su estado actual.", status: :see_other
    end
  end

  def finalizar
    authorize @event, :update?
    if @event.en_curso?
      @event.finalizado!
      redirect_to @event, notice: "Evento finalizado.", status: :see_other
    else
      redirect_to @event, alert: "Solo se puede finalizar un evento que esté en curso.", status: :see_other
    end
  end

  private

  def set_event
    @event = Event.find(params.expect(:id))
  end

  def force_organization!(event)
    event.organization = current_user.organization if current_user.organizador?
  end

  def auto_cancelar_expirados
    Event.auto_cancelar_no_iniciados!
  end

  def event_params
    params.expect(event: [:title, :description, :date, :status, :location,
                           :organization_id, :emergency_level, :emergency_type,
                           :min_score, { required_skills: [] }])
  end
end
