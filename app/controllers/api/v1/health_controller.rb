class Api::V1::HealthController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [ :check ]

  def check
    begin
      # Проверяем подключение к базе данных
      ActiveRecord::Base.connection.execute("SELECT 1")

      render_success({
        status: "OK",
        timestamp: Time.current.iso8601,
        version: "1.0.0",
        database: "connected",
        environment: Rails.env
      })
    rescue => e
      render_error("Health check failed: #{e.message}", :service_unavailable)
    end
  end
end
