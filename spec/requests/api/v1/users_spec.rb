require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, :admin) }
  let(:other_user) { create(:user) }

  let(:valid_headers) { { 'X-User-ID' => user.id.to_s } }
  let(:admin_headers) { { 'X-User-ID' => admin_user.id.to_s } }
  let(:other_user_headers) { { 'X-User-ID' => other_user.id.to_s } }

  describe 'POST /api/v1/users/register' do
    let(:valid_params) do
      {
        user: {
          name: 'New User',
          email: 'newuser@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/v1/users/register', params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['name']).to eq('New User')
        expect(json['data']['email']).to eq('newuser@example.com')
        expect(json['data']).not_to have_key('password')
        expect(json['data']).not_to have_key('password_digest')
      end

      it 'sets admin to false by default' do
        post '/api/v1/users/register', params: valid_params

        json = JSON.parse(response.body)
        expect(json['data']['admin']).to be false
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors for missing email' do
        invalid_params = valid_params.dup
        invalid_params[:user][:email] = ''

        post '/api/v1/users/register', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json['success']).to be false
        expect(json['error']).to eq('Ошибка валидации')
        expect(json['errors']).to be_present
      end

      it 'returns validation errors for password mismatch' do
        invalid_params = valid_params.dup
        invalid_params[:user][:password_confirmation] = 'different'

        post '/api/v1/users/register', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it 'returns validation errors for duplicate email' do
        existing_user = create(:user, email: 'newuser@example.com')

        post '/api/v1/users/register', params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it 'returns validation errors for short password' do
        invalid_params = valid_params.dup
        invalid_params[:user][:password] = '123'
        invalid_params[:user][:password_confirmation] = '123'

        post '/api/v1/users/register', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'POST /api/v1/users' do
    let(:valid_params) do
      {
        user: {
          name: 'New User via Create',
          email: 'create@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    it 'creates a user (alias for register)' do
      expect {
        post '/api/v1/users', params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['data']['name']).to eq('New User via Create')
    end
  end

  describe 'GET /api/v1/users/:id/profile' do
    context 'with valid authentication' do
      it 'returns user profile' do
        get "/api/v1/users/#{user.id}/profile", headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['id']).to eq(user.id)
        expect(json['data']['name']).to eq(user.name)
        expect(json['data']['email']).to eq(user.email)
        expect(json['data']).not_to have_key('password')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get "/api/v1/users/#{user.id}/profile"

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Необходима аутентификация')
      end
    end
  end

  describe 'GET /api/v1/users/:id' do
    context 'viewing own profile' do
      it 'returns user data' do
        get "/api/v1/users/#{user.id}", headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['id']).to eq(user.id)
        expect(json['data']['name']).to eq(user.name)
      end
    end

    context 'admin viewing other user' do
      it 'allows access' do
        get "/api/v1/users/#{other_user.id}", headers: admin_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['id']).to eq(other_user.id)
      end
    end

    context 'non-admin viewing other user' do
      it 'returns access denied' do
        get "/api/v1/users/#{other_user.id}", headers: valid_headers

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Недостаточно прав доступа')
      end
    end

    context 'with non-existent user' do
      it 'returns not found' do
        get '/api/v1/users/999999', headers: valid_headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Пользователь не найден')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get "/api/v1/users/#{user.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/users/:id' do
    let(:update_params) do
      {
        user: {
          name: 'Updated Name',
          email: 'updated@example.com'
        }
      }
    end

    context 'updating own profile' do
      it 'updates user data' do
        put "/api/v1/users/#{user.id}", params: update_params, headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['name']).to eq('Updated Name')
        expect(json['data']['email']).to eq('updated@example.com')

        user.reload
        expect(user.name).to eq('Updated Name')
        expect(user.email).to eq('updated@example.com')
      end

      it 'updates password when provided' do
        password_params = update_params.dup
        password_params[:user][:password] = 'newpassword123'
        password_params[:user][:password_confirmation] = 'newpassword123'

        put "/api/v1/users/#{user.id}", params: password_params, headers: valid_headers

        expect(response).to have_http_status(:ok)

        user.reload
        expect(user.authenticate('newpassword123')).to be_truthy
      end

      it 'does not update password when not provided' do
        original_digest = user.password_digest

        put "/api/v1/users/#{user.id}", params: update_params, headers: valid_headers

        expect(response).to have_http_status(:ok)

        user.reload
        expect(user.password_digest).to eq(original_digest)
      end
    end

    context 'updating other user profile' do
      it 'returns access denied' do
        put "/api/v1/users/#{other_user.id}", params: update_params, headers: valid_headers

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Недостаточно прав доступа')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        invalid_params = { user: { email: 'invalid-email' } }

        put "/api/v1/users/#{user.id}", params: invalid_params, headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it 'returns validation errors for duplicate email' do
        existing_user = create(:user, email: 'existing@example.com')
        duplicate_email_params = { user: { email: 'existing@example.com' } }

        put "/api/v1/users/#{user.id}", params: duplicate_email_params, headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'with non-existent user' do
      it 'returns not found' do
        put '/api/v1/users/999999', params: update_params, headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        put "/api/v1/users/#{user.id}", params: update_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'Authentication behavior' do
    context 'with invalid user ID header' do
      let(:invalid_headers) { { 'X-User-ID' => '999999' } }

      it 'returns unauthorized for non-existent user' do
        get "/api/v1/users/#{user.id}", headers: invalid_headers

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Необходима аутентификация')
      end
    end

    context 'with malformed user ID header' do
      let(:malformed_headers) { { 'X-User-ID' => 'not-a-number' } }

      it 'returns unauthorized' do
        get "/api/v1/users/#{user.id}", headers: malformed_headers

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Необходима аутентификация')
      end
    end
  end
end
