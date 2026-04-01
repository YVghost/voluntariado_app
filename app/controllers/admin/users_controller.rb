class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[edit update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_create_params)

    if @user.save
      redirect_to admin_dashboard_index_path(tab: "usuarios"), notice: "Usuario creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    # Si el campo contraseña viene vacío, no lo actualizamos
    update_params = user_update_params
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      redirect_to admin_dashboard_index_path(tab: "usuarios"), notice: "Usuario actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_create_params
    params.require(:user).permit(
      :nombres, :apellidos, :cedula, :email, :role,
      :password, :password_confirmation
    )
  end

  def user_update_params
    params.require(:user).permit(
      :nombres, :apellidos, :cedula, :email, :role,
      :password, :password_confirmation
    )
  end
end
