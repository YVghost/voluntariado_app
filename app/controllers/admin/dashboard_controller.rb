class Admin::DashboardController < Admin::BaseController

  def index
    @users         = User.order(:created_at)
    @organizations = Organization.includes(:user).order(:created_at)
    @events        = Event.includes(:organization).order(:created_at)
    @enrollments   = Enrollment.includes(:user, :event).order(:created_at)
  end

  def destroy_user
    user = User.find(params[:id])
    user.destroy!
    redirect_to admin_dashboard_index_path, notice: "Usuario eliminado.", status: :see_other
  end

  def destroy_event
    event = Event.find(params[:id])
    event.destroy!
    redirect_to admin_dashboard_index_path, notice: "Evento eliminado.", status: :see_other
  end

  def destroy_organization
    org = Organization.find(params[:id])
    org.destroy!
    redirect_to admin_dashboard_index_path, notice: "Organización eliminada.", status: :see_other
  end

  def destroy_enrollment
    enrollment = Enrollment.find(params[:id])
    enrollment.destroy!
    redirect_to admin_dashboard_index_path, notice: "Inscripción eliminada.", status: :see_other
  end

  def update_user_role
    user = User.find(params[:id])
    user.update!(role: params[:role])
    redirect_to admin_dashboard_index_path, notice: "Rol actualizado.", status: :see_other
  end

end
