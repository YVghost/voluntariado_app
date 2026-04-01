class OrganizationsController < ApplicationController
  before_action :set_organization, only: %i[ show edit update destroy ]

  def index
    @organizations = policy_scope(Organization)
    authorize Organization
  end

  def show
    authorize @organization
  end

  def new
    @organization = Organization.new
    authorize @organization
  end

  def edit
    authorize @organization
  end

  def create
    @organization = Organization.new(organization_params)
    authorize @organization

    if @organization.save
      redirect_to @organization, notice: "Organización creada correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @organization

    if @organization.update(organization_params)
      redirect_to @organization, notice: "Organización actualizada correctamente.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @organization
    @organization.destroy!
    redirect_to organizations_path, notice: "Organización eliminada.", status: :see_other
  end

  private

  def set_organization
    @organization = Organization.find(params.expect(:id))
  end

  def organization_params
    params.expect(organization: [ :name, :ruc, :description, :location ])
  end
end
