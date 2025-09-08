class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user!, except: [ :health, :check ]

  protected

  def authenticate_user!
    # TODO: Implement JWT authentication in next phase
    # For now, we'll use a simple approach for development
    @current_user = User.find_by(id: request.headers["X-User-ID"])

    unless @current_user
      render_error("Необходима аутентификация", :unauthorized)
    end
  end

  def current_user
    @current_user
  end

  def render_success(data = nil, status = :ok)
    response = { success: true }
    response[:data] = data if data

    render json: response, status: status
  end

  def render_error(message, status = :unprocessable_entity, errors = nil)
    response = {
      success: false,
      error: message
    }
    response[:errors] = errors if errors

    render json: response, status: status
  end

  def render_validation_errors(record)
    render_error(
      "Ошибка валидации",
      :unprocessable_entity,
      record.errors.full_messages
    )
  end

  def render_not_found(resource_name = "Ресурс")
    render_error("#{resource_name} не найден", :not_found)
  end

  def render_access_denied
    render_error("Недостаточно прав доступа", :forbidden)
  end

  def paginate_collection(collection, per_page = 20)
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || per_page
    per_page = 100 if per_page > 100 # Ограничиваем максимальный размер страницы

    collection.limit(per_page).offset((page - 1) * per_page)
  end

  def pagination_meta(collection, per_page = 20)
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || per_page
    per_page = 100 if per_page > 100

    total_count = collection.count
    total_pages = (total_count.to_f / per_page).ceil

    {
      current_page: page,
      per_page: per_page,
      total_pages: total_pages,
      total_count: total_count,
      has_next_page: page < total_pages,
      has_prev_page: page > 1
    }
  end
end
