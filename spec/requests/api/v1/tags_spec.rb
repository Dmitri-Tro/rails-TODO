require 'rails_helper'

RSpec.describe 'Tags API', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:valid_headers) { { 'X-User-ID' => user.id.to_s } }

  describe 'GET /api/v1/tags' do
    let!(:tag1) { create(:tag, user: user, name: 'urgent', color: '#ff0000') }
    let!(:tag2) { create(:tag, user: user, name: 'work', color: '#00ff00') }
    let!(:tag3) { create(:tag, user: other_user, name: 'other_user_tag') }

    context 'with valid authentication' do
      it 'returns user tags only' do
        get '/api/v1/tags', headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['tags'].size).to eq(2)
        expect(json['data']['meta']).to include('current_page', 'per_page', 'total_count')

        tag_names = json['data']['tags'].map { |t| t['name'] }
        expect(tag_names).to include('urgent', 'work')
        expect(tag_names).not_to include('other_user_tag')
      end

      it 'includes tasks information' do
        task = create(:task, user: user)
        create(:task_tag, task: task, tag: tag1)

        get '/api/v1/tags', headers: valid_headers

        json = JSON.parse(response.body)
        urgent_tag = json['data']['tags'].find { |t| t['name'] == 'urgent' }
        expect(urgent_tag['tasks_count']).to eq(1)
      end

      context 'filtering' do
        before do
          task = create(:task, user: user)
          create(:task_tag, task: task, tag: tag1)
          # tag2 remains unused
        end

        it 'filters tags by name search' do
          get '/api/v1/tags', params: { search: 'urgent' }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['tags'].size).to eq(1)
          expect(json['data']['tags'][0]['name']).to eq('urgent')
        end

        it 'filters tags with tasks' do
          get '/api/v1/tags', params: { with_tasks: 'true' }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['tags'].size).to eq(1)
          expect(json['data']['tags'][0]['name']).to eq('urgent')
        end

        it 'filters unused tags' do
          get '/api/v1/tags', params: { unused: 'true' }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['tags'].size).to eq(1)
          expect(json['data']['tags'][0]['name']).to eq('work')
        end

        it 'filters tags by color' do
          get '/api/v1/tags', params: { color: '#ff0000' }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['tags'].size).to eq(1)
          expect(json['data']['tags'][0]['name']).to eq('urgent')
          expect(json['data']['tags'][0]['color']).to eq('#ff0000')
        end
      end

      context 'sorting' do
        it 'sorts by name ascending' do
          get '/api/v1/tags', params: { sort_by: 'name', order: 'asc' }, headers: valid_headers

          json = JSON.parse(response.body)
          names = json['data']['tags'].map { |t| t['name'] }
          expect(names).to eq([ 'urgent', 'work' ])
        end

        it 'sorts by name descending' do
          get '/api/v1/tags', params: { sort_by: 'name', order: 'desc' }, headers: valid_headers

          json = JSON.parse(response.body)
          names = json['data']['tags'].map { |t| t['name'] }
          expect(names).to eq([ 'work', 'urgent' ])
        end

        xit 'sorts by usage count' do
          task1 = create(:task, user: user)
          task2 = create(:task, user: user)
          task3 = create(:task, user: user)

          create(:task_tag, task: task1, tag: tag1)
          create(:task_tag, task: task2, tag: tag2)
          create(:task_tag, task: task3, tag: tag2)

          get '/api/v1/tags', params: { sort_by: 'usage', order: 'desc' }, headers: valid_headers

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true

          # Check that we got tags back and they're sorted
          tags = json['data']['tags']
          expect(tags).to be_present
          expect(tags.size).to eq(2)

          # The tag with 2 tasks should come first when sorted by usage desc
          first_tag = tags.first
          expect(first_tag['name']).to eq('work')
        end

        it 'sorts by created_at' do
          # tag1 was created first, then tag2
          get '/api/v1/tags', params: { sort_by: 'created_at', order: 'asc' }, headers: valid_headers

          json = JSON.parse(response.body)
          names = json['data']['tags'].map { |t| t['name'] }
          expect(names.first).to eq('urgent') # Created first
        end
      end

      context 'pagination' do
        before do
          create_list(:tag, 25, user: user)
        end

        it 'paginates results' do
          get '/api/v1/tags', params: { per_page: 10, page: 1 }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['tags'].size).to eq(10)
          expect(json['data']['meta']['current_page']).to eq(1)
          expect(json['data']['meta']['total_count']).to eq(27) # 25 + 2 original
        end
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/tags'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/tags/:id' do
    let(:tag) { create(:tag, user: user) }
    let(:other_user_tag) { create(:tag, user: other_user) }

    context 'with valid tag' do
      it 'returns the tag' do
        get "/api/v1/tags/#{tag.id}", headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['id']).to eq(tag.id)
        expect(json['data']['name']).to eq(tag.name)
      end
    end

    context 'with other user tag' do
      it 'returns not found' do
        get "/api/v1/tags/#{other_user_tag.id}", headers: valid_headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Тег не найден')
      end
    end

    context 'with non-existent tag' do
      it 'returns not found' do
        get '/api/v1/tags/999999', headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/tags' do
    let(:valid_params) do
      {
        tag: {
          name: 'new-tag',
          color: '#0000ff'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new tag' do
        expect {
          post '/api/v1/tags', params: valid_params, headers: valid_headers
        }.to change(Tag, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['name']).to eq('new-tag')
        expect(json['data']['user_id']).to eq(user.id)
        expect(json['data']['color']).to eq('#0000ff')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors for missing name' do
        invalid_params = { tag: { color: '#ff0000' } }

        post '/api/v1/tags', params: invalid_params, headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json['success']).to be false
        expect(json['error']).to eq('Ошибка валидации')
        expect(json['errors']).to be_present
      end

      it 'returns validation errors for duplicate name within user scope' do
        create(:tag, user: user, name: 'duplicate-tag')
        duplicate_params = { tag: { name: 'duplicate-tag' } }

        post '/api/v1/tags', params: duplicate_params, headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it 'allows same name for different users' do
        create(:tag, user: other_user, name: 'shared-tag')
        same_name_params = { tag: { name: 'shared-tag' } }

        expect {
          post '/api/v1/tags', params: same_name_params, headers: valid_headers
        }.to change(Tag, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns validation errors for invalid color format' do
        invalid_color_params = { tag: { name: 'test-tag', color: 'invalid-color' } }

        post '/api/v1/tags', params: invalid_color_params, headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'PUT /api/v1/tags/:id' do
    let(:tag) { create(:tag, user: user, name: 'original-name') }
    let(:update_params) do
      {
        tag: {
          name: 'updated-name',
          color: '#ff00ff'
        }
      }
    end

    context 'with valid parameters' do
      it 'updates the tag' do
        put "/api/v1/tags/#{tag.id}", params: update_params, headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['name']).to eq('updated-name')
        expect(json['data']['color']).to eq('#ff00ff')

        tag.reload
        expect(tag.name).to eq('updated-name')
      end
    end

    context 'with other user tag' do
      let(:other_tag) { create(:tag, user: other_user) }

      it 'returns not found' do
        put "/api/v1/tags/#{other_tag.id}", params: update_params, headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        invalid_params = { tag: { name: '', color: 'invalid' } }

        put "/api/v1/tags/#{tag.id}", params: invalid_params, headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'DELETE /api/v1/tags/:id' do
    context 'tag without tasks' do
      let(:tag) { create(:tag, user: user) }

      it 'deletes the tag' do
        tag_id = tag.id

        expect {
          delete "/api/v1/tags/#{tag_id}", headers: valid_headers
        }.to change(Tag, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(Tag.find_by(id: tag_id)).to be_nil
      end
    end

    context 'tag with tasks' do
      let(:tag) { create(:tag, user: user) }

      before do
        task = create(:task, user: user)
        create(:task_tag, task: task, tag: tag)
      end

      it 'prevents deletion and returns error' do
        expect {
          delete "/api/v1/tags/#{tag.id}", headers: valid_headers
        }.not_to change(Tag, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to be_present
      end
    end

    context 'with other user tag' do
      let(:other_tag) { create(:tag, user: other_user) }

      it 'returns not found' do
        delete "/api/v1/tags/#{other_tag.id}", headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'Popular tags filtering' do
    before do
      # Create tags with different usage levels
      @high_usage_tag = create(:tag, user: user, name: 'high-usage')
      @low_usage_tag = create(:tag, user: user, name: 'low-usage')

      # Create tasks and associate with tags to simulate usage
      tasks = create_list(:task, 10, user: user)

      # High usage tag: 8 out of 10 tasks (80% usage)
      tasks.first(8).each do |task|
        create(:task_tag, task: task, tag: @high_usage_tag)
      end

      # Low usage tag: 2 out of 10 tasks (20% usage)
      tasks.first(2).each do |task|
        create(:task_tag, task: task, tag: @low_usage_tag)
      end
    end

    it 'filters popular tags correctly' do
      get '/api/v1/tags', params: { popular: 'true' }, headers: valid_headers

      json = JSON.parse(response.body)
      tag_names = json['data']['tags'].map { |t| t['name'] }

      # Only tags with > 50% usage should be returned
      expect(tag_names).to include('high-usage')
      expect(tag_names).not_to include('low-usage')
    end
  end
end
