class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[edit update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to admin_dashboard_index_path(tab: "usuarios"), notice: "Usuario creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    attrs = user_params
    attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?

    if @user.update(attrs)
      redirect_to admin_dashboard_index_path(tab: "usuarios"), notice: "Usuario actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :nombres, :apellidos, :cedula, :email, :role,
      :password, :password_confirmation
    )
  end
end
