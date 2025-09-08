require 'rails_helper'

RSpec.describe 'Health API', type: :request do
  describe 'GET /api/v1/health' do
    context 'when database is connected' do
      it 'returns health status' do
        get '/api/v1/health'

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']).to include(
          'status' => 'OK',
          'timestamp' => be_present,
          'version' => '1.0.0',
          'database' => 'connected',
          'environment' => Rails.env
        )
        expect(json['data']['timestamp']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end

      it 'does not require authentication' do
        get '/api/v1/health'

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['success']).to be true
      end
    end

    context 'when database connection fails' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute)
          .with("SELECT 1")
          .and_raise(StandardError.new("Connection failed"))
      end

      it 'returns service unavailable status' do
        get '/api/v1/health'

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)

        expect(json['success']).to be false
        expect(json['error']).to eq('Health check failed: Connection failed')
      end
    end

    context 'when unexpected error occurs' do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute)
          .and_raise(RuntimeError.new("Unexpected error"))
      end

      it 'returns service unavailable with error message' do
        get '/api/v1/health'

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)

        expect(json['success']).to be false
        expect(json['error']).to eq('Health check failed: Unexpected error')
      end
    end
  end
end
