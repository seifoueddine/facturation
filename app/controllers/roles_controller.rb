class RolesController < ApplicationController

  before_action :set_role, only: %i[show edit update destroy]

  def index
    @roles = Role.all.where(for_client: false)
    @client_roles = Role.all.where(for_client: true)
  end

  def show
    @role = Role.find(params[:id])
  end

  def new
    @role = Role.new
    build_permissions
    # @role.permissions.build
    respond_to do |format|
      format.js
    end
  end

  def edit
    build_permissions unless @role.permissions.exists?
    respond_to do |format|
      format.js
    end
  end

  def create
    @role = Role.new(role_params)
    respond_to do |format|
      if @role.save
        format.js {
          flash[:notice]= 'Role has been created successfully'
          render :js => "window.location.href='#{roles_path}'"
        }
        format.html {redirect_to roles_path}
      else
        format.js
      end
    end
  end

  def update
    respond_to do |format|
      if @role.update(role_params)
        format.js
      end
    end
  end

  def destroy
    @role.destroy
    if @role.destroy
      render json: {location: roles_path}
    end
  end

  def roles_settings
    @roles = Role.all
    render layout: false
  end

  def destroy_bulk
    @role = Role.where(id: params[:role_ids]).destroy_all
    @roles = Role.all
    render json: {notice: t('views.Roles.deleted_msg')}, status: :ok
  end

  private

  def role_params
    params.require(:role).permit(:name, :for_client, permissions_attributes: [:id, :role_id, :can_create, :can_update, :can_delete, :can_read, :entity_type])
  end

  def set_role
    @role = Role.find(params[:id])
  end

  def build_permissions
    entity_types = params[:for_client].present? ? CLIENT_ENTITY_TYPES : ENTITY_TYPES
    entity_types.each do |e|
      @role.permissions.build(entity_type: e)
    end
  end
end
