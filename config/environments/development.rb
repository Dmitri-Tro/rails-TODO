require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Настройки логирования
  config.log_level = :debug                    # Уровень логирования: :debug, :info, :warn, :error, :fatal
  config.log_tags = [:request_id, :remote_ip]  # Теги для логов
  config.logger = ActiveSupport::Logger.new(STDOUT)  # Вывод в консоль
  
  # Настройки отладки для API
  config.debug_exception_response_format = :api  # JSON ответы для ошибок
  config.consider_all_requests_local = true     # Показывать детали ошибок
  
  # Логирование SQL запросов
  config.log_sql_queries = true                # Логировать SQL запросы
  config.log_sql_parameters = true             # Логировать параметры SQL
  
  # Логирование параметров запросов
  config.log_parameter_filter = [:password, :token, :secret]  # Фильтровать чувствительные данные
  
  # Настройки кэширования
  config.cache_classes = false                 # Перезагружать классы при изменении
  config.reload_classes_only_on_change = true  # Перезагружать только при изменении
  
  # Настройки отладки
  config.eager_load = false                    # Не загружать все классы сразу
  config.require_master_key = false            # Не требовать master key в development
  
  # Логирование маршрутов
  config.log_routes = true                     # Логировать маршруты
  
  # Настройки сессий
  config.session_store :cookie_store, key: '_todo_session'
  
  # Настройки cookies
  config.action_dispatch.cookies_serializer = :json
  
  # Настройки CORS для development
  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'  # Разрешить все origins в development
      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: false
    end
  end
end
