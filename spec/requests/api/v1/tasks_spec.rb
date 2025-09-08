require 'rails_helper'

RSpec.describe 'Tasks API', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:category) { create(:category, user: user) }
  let(:tag1) { create(:tag, user: user, name: 'urgent') }
  let(:tag2) { create(:tag, user: user, name: 'work') }

  let(:valid_headers) { { 'X-User-ID' => user.id.to_s } }
  let(:invalid_headers) { { 'X-User-ID' => 'invalid' } }

  describe 'GET /api/v1/tasks' do
    context 'with valid authentication' do
      let!(:task1) { create(:task, user: user, title: 'First task', status: 'pending', priority: 5) }
      let!(:task2) { create(:task, user: user, title: 'Second task', status: 'completed', priority: 3) }
      let!(:task3) { create(:task, user: other_user, title: 'Other user task') }

      it 'returns user tasks only' do
        get '/api/v1/tasks', headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['tasks'].size).to eq(2)
        expect(json['data']['meta']).to include('current_page', 'per_page', 'total_count')

        task_titles = json['data']['tasks'].map { |t| t['title'] }
        expect(task_titles).to include('First task', 'Second task')
        expect(task_titles).not_to include('Other user task')
      end

      context 'filtering' do
        it 'filters by status' do
          get '/api/v1/tasks', params: { status: 'pending' }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['tasks'].size).to eq(1)
          expect(json['data']['tasks'][0]['title']).to eq('First task')
        end

        it 'filters by priority' do
          get '/api/v1/tasks', params: { priority: 5 }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['tasks'].size).to eq(1)
          expect(json['data']['tasks'][0]['priority']).to eq(5)
        end

        it 'filters by category' do
          task1.update!(category: category)

          get '/api/v1/tasks', params: { category_id: category.id }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['tasks'].size).to eq(1)
          expect(json['data']['tasks'][0]['id']).to eq(task1.id)
        end

        it 'searches by title' do
          get '/api/v1/tasks', params: { search: 'First' }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['tasks'].size).to eq(1)
          expect(json['data']['tasks'][0]['title']).to eq('First task')
        end
      end

      context 'sorting' do
        it 'sorts by title ascending' do
          get '/api/v1/tasks', params: { sort_by: 'title', order: 'asc' }, headers: valid_headers

          json = JSON.parse(response.body)
          titles = json['data']['tasks'].map { |t| t['title'] }
          expect(titles).to eq([ 'First task', 'Second task' ])
        end

        it 'sorts by priority' do
          get '/api/v1/tasks', params: { sort_by: 'priority' }, headers: valid_headers

          json = JSON.parse(response.body)
          priorities = json['data']['tasks'].map { |t| t['priority'] }
          expect(priorities.first).to eq(5) # High priority first
        end
      end

      context 'pagination' do
        before do
          create_list(:task, 25, user: user)
        end

        it 'paginates results' do
          get '/api/v1/tasks', params: { per_page: 10, page: 1 }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['tasks'].size).to eq(10)
          expect(json['data']['meta']['current_page']).to eq(1)
          expect(json['data']['meta']['total_count']).to eq(27) # 25 + 2 original
        end
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/tasks'

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to eq('Необходима аутентификация')
      end
    end
  end

  describe 'GET /api/v1/tasks/completed' do
    let!(:completed_task) { create(:task, user: user, status: 'completed') }
    let!(:pending_task) { create(:task, user: user, status: 'pending') }

    it 'returns only completed tasks' do
      get '/api/v1/tasks/completed', headers: valid_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['data']['tasks'].size).to eq(1)
      expect(json['data']['tasks'][0]['status']).to eq('completed')
    end
  end

  describe 'GET /api/v1/tasks/pending' do
    let!(:completed_task) { create(:task, user: user, status: 'completed') }
    let!(:pending_task) { create(:task, user: user, status: 'pending') }

    it 'returns only pending tasks' do
      get '/api/v1/tasks/pending', headers: valid_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['data']['tasks'].size).to eq(1)
      expect(json['data']['tasks'][0]['status']).to eq('pending')
    end
  end

  describe 'GET /api/v1/tasks/in_progress' do
    let!(:in_progress_task) { create(:task, user: user, status: 'in_progress') }
    let!(:pending_task) { create(:task, user: user, status: 'pending') }

    it 'returns only in_progress tasks' do
      get '/api/v1/tasks/in_progress', headers: valid_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['data']['tasks'].size).to eq(1)
      expect(json['data']['tasks'][0]['status']).to eq('in_progress')
    end
  end

  describe 'GET /api/v1/tasks/cancelled' do
    let!(:cancelled_task) { create(:task, user: user, status: 'cancelled') }
    let!(:pending_task) { create(:task, user: user, status: 'pending') }

    it 'returns only cancelled tasks' do
      get '/api/v1/tasks/cancelled', headers: valid_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['data']['tasks'].size).to eq(1)
      expect(json['data']['tasks'][0]['status']).to eq('cancelled')
    end
  end

  describe 'GET /api/v1/tasks/:id' do
    let(:task) { create(:task, user: user) }
    let(:other_user_task) { create(:task, user: other_user) }

    context 'with valid task' do
      it 'returns the task' do
        get "/api/v1/tasks/#{task.id}", headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['id']).to eq(task.id)
        expect(json['data']['title']).to eq(task.title)
      end
    end

    context 'with other user task' do
      it 'returns not found' do
        get "/api/v1/tasks/#{other_user_task.id}", headers: valid_headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Задача не найден')
      end
    end

    context 'with non-existent task' do
      it 'returns not found' do
        get '/api/v1/tasks/999999', headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/tasks' do
    let(:valid_params) do
      {
        task: {
          title: 'New Task',
          description: 'Task description',
          priority: 3,
          due_date: 1.week.from_now.to_s,
          category_id: category.id
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new task' do
        expect {
          post '/api/v1/tasks', params: valid_params, headers: valid_headers
        }.to change(Task, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['title']).to eq('New Task')
        expect(json['data']['user_id']).to eq(user.id)
      end

      it 'creates task with tags' do
        params_with_tags = valid_params.dup
        params_with_tags[:task][:tag_ids] = [ tag1.id, tag2.id ]

        post '/api/v1/tasks', params: params_with_tags, headers: valid_headers

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        task = Task.find(json['data']['id'])
        expect(task.tags.pluck(:id)).to contain_exactly(tag1.id, tag2.id)
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        invalid_params = { task: { title: '' } }

        post '/api/v1/tasks', params: invalid_params, headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json['success']).to be false
        expect(json['error']).to eq('Ошибка валидации')
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'PUT /api/v1/tasks/:id' do
    let(:task) { create(:task, user: user, title: 'Original Title') }
    let(:update_params) do
      {
        task: {
          title: 'Updated Title',
          description: 'Updated description'
        }
      }
    end

    context 'with valid parameters' do
      it 'updates the task' do
        put "/api/v1/tasks/#{task.id}", params: update_params, headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['title']).to eq('Updated Title')

        task.reload
        expect(task.title).to eq('Updated Title')
      end

      it 'updates task tags' do
        params_with_tags = update_params.dup
        params_with_tags[:task][:tag_ids] = [ tag1.id ]

        put "/api/v1/tasks/#{task.id}", params: params_with_tags, headers: valid_headers

        expect(response).to have_http_status(:ok)

        task.reload
        expect(task.tags.pluck(:id)).to contain_exactly(tag1.id)
      end
    end

    context 'with other user task' do
      let(:other_task) { create(:task, user: other_user) }

      it 'returns not found' do
        put "/api/v1/tasks/#{other_task.id}", params: update_params, headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/tasks/:id' do
    let(:task) { create(:task, user: user) }

    context 'with valid task' do
      it 'deletes the task' do
        delete "/api/v1/tasks/#{task.id}", headers: valid_headers

        expect(response).to have_http_status(:no_content)
        expect(Task.find_by(id: task.id)).to be_nil
      end
    end

    context 'with other user task' do
      let(:other_task) { create(:task, user: other_user) }

      it 'returns not found' do
        delete "/api/v1/tasks/#{other_task.id}", headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /api/v1/tasks/:id/complete' do
    let(:task) { create(:task, user: user, status: 'pending') }

    it 'marks task as completed' do
      patch "/api/v1/tasks/#{task.id}/complete", headers: valid_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['success']).to be true
      expect(json['data']['status']).to eq('completed')

      task.reload
      expect(task.status).to eq('completed')
    end

    context 'with other user task' do
      let(:other_task) { create(:task, user: other_user) }

      it 'returns not found' do
        patch "/api/v1/tasks/#{other_task.id}/complete", headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /api/v1/tasks/:id/uncomplete' do
    context 'with completed task' do
      let(:task) { create(:task, user: user, status: 'completed') }

      it 'marks task as pending' do
        patch "/api/v1/tasks/#{task.id}/uncomplete", headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['status']).to eq('pending')

        task.reload
        expect(task.status).to eq('pending')
      end
    end

    context 'with cancelled task' do
      let(:task) { create(:task, user: user, status: 'cancelled') }

      it 'marks task as pending' do
        patch "/api/v1/tasks/#{task.id}/uncomplete", headers: valid_headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['data']['status']).to eq('pending')
      end
    end

    context 'with pending task' do
      let(:task) { create(:task, user: user, status: 'pending') }

      it 'returns error' do
        patch "/api/v1/tasks/#{task.id}/uncomplete", headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Задача уже не завершена')
      end
    end
  end
end
