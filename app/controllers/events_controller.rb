class EventsController < ApplicationController
  before_action :set_event, only: %i[ show edit update destroy finalizar ]

  def index
    @events = Event.all
    authorize Event
  end

  def show
    authorize @event
  end

  def new
    @event = Event.new
    authorize @event
  end

  def edit
    authorize @event
  end

  def create
    @event = Event.new(event_params)
    authorize @event

    if @event.save
      redirect_to @event, notice: "Evento creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @event

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

  def finalizar
    authorize @event, :update?
    @event.finalizado!
    redirect_to @event, notice: "Evento finalizado.", status: :see_other
  end

  private

  def set_event
    @event = Event.find(params.expect(:id))
  end

  def event_params
    params.expect(event: [ :title, :description, :date, :status, :location, :organization_id ])
  end
end
