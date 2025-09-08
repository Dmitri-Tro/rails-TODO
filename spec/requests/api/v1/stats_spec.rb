require 'rails_helper'

RSpec.describe 'Stats API', type: :request do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, :admin) }
  let(:valid_headers) { { 'X-User-ID' => user.id.to_s } }

  describe 'GET /api/v1/stats' do
    context 'with authentication' do
      before do
        # Create test data for comprehensive stats
        admin_user # Force creation of admin user
        regular_user = create(:user)
        category = create(:category, user: user)
        tag1 = create(:tag, user: user)
        tag2 = create(:tag, user: user)

        # Create tasks with various statuses and priorities
        create(:task, user: user, status: 'pending', priority: 5, category: category)
        create(:task, user: user, status: 'in_progress', priority: 3)
        create(:task, user: user, status: 'completed', priority: 1)
        create(:task, user: user, status: 'cancelled', priority: 2)
        create(:task, user: regular_user, status: 'pending', priority: 4)

        # Create overdue and due soon tasks
        create(:task, :overdue, user: user)
        create(:task, :due_soon, user: user)

        # Create task with tags
        task_with_tags = create(:task, user: user)
        create(:task_tag, task: task_with_tags, tag: tag1)
        create(:task_tag, task: task_with_tags, tag: tag2)
      end

      it 'returns comprehensive application statistics' do
        get '/api/v1/stats', headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']).to include(
          'users',
          'tasks',
          'categories',
          'tags'
        )
      end

      it 'returns correct user statistics' do
        get '/api/v1/stats', headers: valid_headers

        json = JSON.parse(response.body)
        users_stats = json['data']['users']

        expect(users_stats).to include(
          'total' => User.count,
          'admins' => User.admins.count,
          'regular' => User.regular_users.count
        )

        expect(users_stats['total']).to be >= 2 # At least user and admin_user
        expect(users_stats['admins']).to be >= 1 # At least admin_user
        expect(users_stats['regular']).to be >= 1 # At least user
      end

      it 'returns correct task statistics' do
        get '/api/v1/stats', headers: valid_headers

        json = JSON.parse(response.body)
        tasks_stats = json['data']['tasks']

        expect(tasks_stats).to include(
          'total' => Task.count,
          'by_status' => include(
            'pending' => Task.pending.count,
            'in_progress' => Task.in_progress.count,
            'completed' => Task.completed.count,
            'cancelled' => Task.cancelled.count
          ),
          'by_priority' => include(
            'high' => Task.high_priority.count,
            'medium' => Task.where(priority: 3).count,
            'low' => Task.where(priority: [ 0, 1, 2 ]).count
          ),
          'overdue' => Task.overdue.count,
          'due_soon' => Task.due_soon.count
        )

        expect(tasks_stats['total']).to be > 0
        expect(tasks_stats['by_status']['pending']).to be > 0
        expect(tasks_stats['overdue']).to be > 0
        expect(tasks_stats['due_soon']).to be > 0
      end

      it 'returns correct category statistics' do
        get '/api/v1/stats', headers: valid_headers

        json = JSON.parse(response.body)
        categories_stats = json['data']['categories']

        expect(categories_stats).to include(
          'total' => Category.count,
          'with_tasks' => Category.joins(:tasks).distinct.count
        )

        expect(categories_stats['total']).to be > 0
        expect(categories_stats['with_tasks']).to be > 0
      end

      it 'returns correct tag statistics' do
        get '/api/v1/stats', headers: valid_headers

        json = JSON.parse(response.body)
        tags_stats = json['data']['tags']

        expect(tags_stats).to include(
          'total' => Tag.count,
          'used' => Tag.joins(:tasks).distinct.count
        )

        expect(tags_stats['total']).to be > 0
        expect(tags_stats['used']).to be > 0
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/stats'

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Необходима аутентификация')
      end
    end

    context 'with empty database' do
      before do
        # Clear all data except authenticated user
        Task.destroy_all
        Category.destroy_all
        Tag.destroy_all
        User.where.not(id: user.id).destroy_all
      end

      it 'returns zero counts appropriately' do
        get '/api/v1/stats', headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['data']['tasks']['total']).to eq(0)
        expect(json['data']['categories']['total']).to eq(0)
        expect(json['data']['tags']['total']).to eq(0)
        expect(json['data']['users']['total']).to eq(1) # Just the authenticated user
      end
    end

    context 'checking stats accuracy over time' do
      it 'updates stats when new data is created' do
        # Get initial stats
        get '/api/v1/stats', headers: valid_headers
        initial_json = JSON.parse(response.body)
        initial_task_count = initial_json['data']['tasks']['total']

        # Create new task
        create(:task, user: user)

        # Get updated stats
        get '/api/v1/stats', headers: valid_headers
        updated_json = JSON.parse(response.body)
        updated_task_count = updated_json['data']['tasks']['total']

        expect(updated_task_count).to eq(initial_task_count + 1)
      end
    end
  end
end
