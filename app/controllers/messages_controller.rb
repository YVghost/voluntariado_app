class MessagesController < ApplicationController
  before_action :set_event

  def create
    @message = @event.messages.new(content: params.dig(:message, :content), user: current_user)
    authorize @message

    if @message.save
      # El broadcast en el modelo agrega el mensaje al DOM automáticamente.
      # Respondemos con turbo_stream para limpiar el formulario.
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(:message_form, partial: "events/message_form", locals: { event: @event })
        }
        format.html { redirect_to @event }
      end
    else
      redirect_to @event, alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
