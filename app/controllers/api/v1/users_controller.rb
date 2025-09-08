class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [ :show, :update, :profile ]
  skip_before_action :authenticate_user!, only: [ :register, :create ]

  # POST /api/v1/users/register
  def register
    user = User.new(user_params)

    if user.save
      render_success(user.to_api_json, :created)
    else
      render_validation_errors(user)
    end
  end

  # POST /api/v1/users
  def create
    # Alias для register для RESTful соответствия
    register
  end

  # GET /api/v1/users/:id/profile
  def profile
    render_success(@user.to_api_json)
  end

  # GET /api/v1/users/:id
  def show
    # Проверяем права доступа - пользователь может видеть только свой профиль или админ может видеть любой
    unless @user == current_user || current_user.admin?
      render_access_denied
      return
    end

    render_success(@user.to_api_json)
  end

  # PUT/PATCH /api/v1/users/:id
  def update
    # Проверяем права доступа - пользователь может обновлять только свой профиль
    unless @user == current_user
      render_access_denied
      return
    end

    if @user.update(user_update_params)
      render_success(@user.to_api_json)
    else
      render_validation_errors(@user)
    end
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])

    unless @user
      render_not_found("Пользователь")
      nil
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def user_update_params
    allowed_params = [ :name, :email ]
    allowed_params += [ :password, :password_confirmation ] if params[:user][:password].present?

    params.require(:user).permit(*allowed_params)
  end
end
