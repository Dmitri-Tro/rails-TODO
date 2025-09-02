Rails.application.configure do
  # Настройки для тестового окружения
  
  # Настройки кэширования
  config.cache_classes = true
  config.eager_load = false
  
  # Настройки логирования
  config.log_level = :warn
  config.logger = ActiveSupport::Logger.new(nil)
  
  # Настройки публичных файлов
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }
  
  # Настройки тестирования
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = false
  config.action_controller.allow_forgery_protection = false
  
  # Настройки ActionMailer
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test
  
  # Настройки ActiveStorage
  config.active_storage.service = :test
  
  # Настройки ActionCable
  config.action_cable.disable_request_forgery_protection = true
  
  # Настройки базы данных
  config.active_record.dump_schema_after_migration = false
  
  # Настройки middleware
  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: false
    end
  end
end