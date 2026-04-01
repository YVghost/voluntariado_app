class Admin::OrganizationsController < Admin::BaseController
  before_action :set_organization, only: %i[edit update]

  def new
    @organization = Organization.new
    @rep = @organization.build_user
  end

  def create
    ActiveRecord::Base.transaction do
      # Crear o asignar representante
      @rep = User.new(representante_params)
      @rep.role = :organizador
      @rep.save!

      @organization = Organization.new(org_params)
      @organization.user = @rep
      @organization.save!
    end

    redirect_to admin_dashboard_index_path(tab: "organizaciones"), notice: "Organización creada correctamente."
  rescue ActiveRecord::RecordInvalid
    @organization ||= Organization.new(org_params)
    @rep           ||= User.new(representante_params)
    @rep.valid?
    @organization.valid?
    render :new, status: :unprocessable_entity
  end

  def edit
    @rep = @organization.user || @organization.build_user
  end

  def update
    ActiveRecord::Base.transaction do
      # Actualizar datos de la organización
      @organization.update!(org_params)

      # Actualizar datos del representante si existe
      if @organization.user.present?
        rep_attrs = representante_params
        if rep_attrs[:password].blank?
          rep_attrs = rep_attrs.except(:password, :password_confirmation)
        end
        @organization.user.update!(rep_attrs)
      end
    end

    redirect_to admin_dashboard_index_path(tab: "organizaciones"), notice: "Organización actualizada correctamente."
  rescue ActiveRecord::RecordInvalid
    @rep = @organization.user || @organization.build_user
    render :edit, status: :unprocessable_entity
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def org_params
    params.require(:organization).permit(:name, :ruc, :description, :location)
  end

  def representante_params
    params.require(:representante).permit(
      :nombres, :apellidos, :cedula, :email,
      :password, :password_confirmation
    )
  end
end
