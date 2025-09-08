class ApplicationController < ActionController::API
  # Глобальная обработка ошибок
  rescue_from StandardError, with: :handle_internal_server_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from JSON::ParserError, with: :handle_json_parse_error

  private

  def handle_not_found(exception)
    render json: {
      success: false,
      error: "Ресурс не найден",
      details: exception.message
    }, status: :not_found
  end

  def handle_validation_error(exception)
    render json: {
      success: false,
      error: "Ошибка валидации",
      errors: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def handle_parameter_missing(exception)
    render json: {
      success: false,
      error: "Отсутствует обязательный параметр",
      details: exception.message
    }, status: :bad_request
  end

  def handle_json_parse_error(exception)
    render json: {
      success: false,
      error: "Некорректный JSON",
      details: exception.message
    }, status: :bad_request
  end

  def handle_internal_server_error(exception)
    # Логируем ошибку
    Rails.logger.error "Internal Server Error: #{exception.class}: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")

    # В production не показываем подробности ошибки
    if Rails.env.production?
      render json: {
        success: false,
        error: "Внутренняя ошибка сервера"
      }, status: :internal_server_error
    else
      render json: {
        success: false,
        error: "Внутренняя ошибка сервера",
        details: exception.message,
        backtrace: exception.backtrace.first(10)
      }, status: :internal_server_error
    end
  end
end
