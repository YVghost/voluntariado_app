class Admin::EventsController < Admin::BaseController
  def available_volunteers
    event = Event.find(params[:id])
    enrolled_ids = event.enrollments.where.not(status: :cancelado).pluck(:user_id)
    volunteers = User.where(role: :voluntario)
                     .where.not(id: enrolled_ids)
                     .order(:name)
                     .select(:id, :name)
    render json: volunteers.map { |u| { id: u.id, name: u.name } }
  end
end
