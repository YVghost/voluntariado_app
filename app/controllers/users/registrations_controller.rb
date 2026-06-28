class Users::RegistrationsController < Devise::RegistrationsController
  def new
    super
    @registration_type = "voluntario"
  end

  def create
    @registration_type = params[:registration_type].presence || "voluntario"

    if @registration_type == "organizacion"
      create_organizacion
    else
      create_voluntario
    end
  end

  private

  def create_voluntario
    build_resource(voluntario_params)
    resource.role = :voluntario

    if resource.save
      sign_in resource
      redirect_to root_path, notice: "¡Bienvenido/a #{resource.nombres}! Tu cuenta fue creada correctamente."
    else
      clean_up_passwords resource
      render :new, status: :unprocessable_entity
    end
  end

  def create_organizacion
    ActiveRecord::Base.transaction do
      build_resource(representante_params)
      resource.role = :organizador

      resource.save!

      @organization = Organization.new(organizacion_params)
      @organization.user = resource
      @organization.save!
    end

    sign_in resource
    redirect_to root_path, notice: "¡Bienvenidos! La organización fue registrada correctamente."
  rescue ActiveRecord::RecordInvalid
    clean_up_passwords resource
    @organization ||= Organization.new(organizacion_params)
    @organization.valid? unless @organization.errors.any?

    # Propagamos errores de la organización al resource para que aparezcan en la vista
    @organization.errors.full_messages.each do |msg|
      resource.errors.add(:base, "Organización — #{msg}")
    end

    # Si el resource tampoco tiene errores propios (guardó bien antes del rollback)
    # agregamos un mensaje genérico para que el bloque de errores se muestre
    if resource.errors.none?
      resource.errors.add(:base, "No se pudo guardar la organización. Revisá los datos.")
    end

    @registration_type = "organizacion"
    render :new, status: :unprocessable_entity
  end

  def user_registration_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      :nombres, :apellidos, :cedula
    )
  end
  alias_method :voluntario_params, :user_registration_params
  alias_method :representante_params, :user_registration_params

  def organizacion_params
    params.require(:organization).permit(:ruc, :name, :description, :location)
  end
end
