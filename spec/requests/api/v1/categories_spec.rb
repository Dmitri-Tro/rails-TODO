require 'rails_helper'

RSpec.describe 'Categories API', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:valid_headers) { { 'X-User-ID' => user.id.to_s } }

  describe 'GET /api/v1/categories' do
    let!(:category1) { create(:category, user: user, name: 'Work', color: '#ff0000') }
    let!(:category2) { create(:category, user: user, name: 'Personal', color: '#00ff00') }
    let!(:category3) { create(:category, user: other_user, name: 'Other User Category') }

    context 'with valid authentication' do
      it 'returns user categories only' do
        get '/api/v1/categories', headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['categories'].size).to eq(2)
        expect(json['data']['meta']).to include('current_page', 'per_page', 'total_count')

        category_names = json['data']['categories'].map { |c| c['name'] }
        expect(category_names).to include('Work', 'Personal')
        expect(category_names).not_to include('Other User Category')
      end

      it 'includes tasks in the response' do
        task = create(:task, user: user, category: category1)

        get '/api/v1/categories', headers: valid_headers

        json = JSON.parse(response.body)
        work_category = json['data']['categories'].find { |c| c['name'] == 'Work' }
        expect(work_category['tasks_count']).to eq(1)
      end

      context 'filtering' do
        before do
          create(:task, user: user, category: category1)
          # category2 remains empty
        end

        it 'filters categories by name search' do
          get '/api/v1/categories', params: { search: 'Work' }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['categories'].size).to eq(1)
          expect(json['data']['categories'][0]['name']).to eq('Work')
        end

        it 'filters categories with tasks' do
          get '/api/v1/categories', params: { with_tasks: 'true' }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['categories'].size).to eq(1)
          expect(json['data']['categories'][0]['name']).to eq('Work')
        end

        it 'filters empty categories' do
          get '/api/v1/categories', params: { empty: 'true' }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['categories'].size).to eq(1)
          expect(json['data']['categories'][0]['name']).to eq('Personal')
        end
      end

      context 'sorting' do
        it 'sorts by name ascending' do
          get '/api/v1/categories', params: { sort_by: 'name', order: 'asc' }, headers: valid_headers

          json = JSON.parse(response.body)
          names = json['data']['categories'].map { |c| c['name'] }
          expect(names).to eq([ 'Personal', 'Work' ])
        end

        it 'sorts by name descending' do
          get '/api/v1/categories', params: { sort_by: 'name', order: 'desc' }, headers: valid_headers

          json = JSON.parse(response.body)
          names = json['data']['categories'].map { |c| c['name'] }
          expect(names).to eq([ 'Work', 'Personal' ])
        end

        xit 'sorts by tasks count' do
          create(:task, user: user, category: category1)
          create_list(:task, 2, user: user, category: category2)

          get '/api/v1/categories', params: { sort_by: 'tasks_count', order: 'desc' }, headers: valid_headers

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true

          # Check that we got categories back and they're sorted
          categories = json['data']['categories']
          expect(categories).to be_present
          expect(categories.size).to eq(2)

          # The category with 2 tasks should come first when sorted by count desc
          first_category = categories.first
          expect(first_category['name']).to eq('Personal')
        end
      end

      context 'pagination' do
        before do
          create_list(:category, 25, user: user)
        end

        it 'paginates results' do
          get '/api/v1/categories', params: { per_page: 10, page: 1 }, headers: valid_headers

          json = JSON.parse(response.body)
          expect(json['data']['categories'].size).to eq(10)
          expect(json['data']['meta']['current_page']).to eq(1)
          expect(json['data']['meta']['total_count']).to eq(27) # 25 + 2 original
        end
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/categories'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/categories/:id' do
    let(:category) { create(:category, user: user) }
    let(:other_user_category) { create(:category, user: other_user) }

    context 'with valid category' do
      it 'returns the category' do
        get "/api/v1/categories/#{category.id}", headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['id']).to eq(category.id)
        expect(json['data']['name']).to eq(category.name)
      end
    end

    context 'with other user category' do
      it 'returns not found' do
        get "/api/v1/categories/#{other_user_category.id}", headers: valid_headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Категория не найден')
      end
    end

    context 'with non-existent category' do
      it 'returns not found' do
        get '/api/v1/categories/999999', headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/categories' do
    let(:valid_params) do
      {
        category: {
          name: 'New Category',
          description: 'Category description',
          color: '#0000ff'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new category' do
        expect {
          post '/api/v1/categories', params: valid_params, headers: valid_headers
        }.to change(Category, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['name']).to eq('New Category')
        expect(json['data']['user_id']).to eq(user.id)
        expect(json['data']['color']).to eq('#0000ff')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors for missing name' do
        invalid_params = { category: { description: 'No name' } }

        post '/api/v1/categories', params: invalid_params, headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json['success']).to be false
        expect(json['error']).to eq('Ошибка валидации')
        expect(json['errors']).to be_present
      end

      it 'returns validation errors for duplicate name within user scope' do
        create(:category, user: user, name: 'Duplicate Category')
        duplicate_params = { category: { name: 'Duplicate Category' } }

        post '/api/v1/categories', params: duplicate_params, headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it 'allows same name for different users' do
        create(:category, user: other_user, name: 'Shared Name')
        same_name_params = { category: { name: 'Shared Name' } }

        expect {
          post '/api/v1/categories', params: same_name_params, headers: valid_headers
        }.to change(Category, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe 'PUT /api/v1/categories/:id' do
    let(:category) { create(:category, user: user, name: 'Original Name') }
    let(:update_params) do
      {
        category: {
          name: 'Updated Name',
          description: 'Updated description',
          color: '#ff00ff'
        }
      }
    end

    context 'with valid parameters' do
      it 'updates the category' do
        put "/api/v1/categories/#{category.id}", params: update_params, headers: valid_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['success']).to be true
        expect(json['data']['name']).to eq('Updated Name')
        expect(json['data']['color']).to eq('#ff00ff')

        category.reload
        expect(category.name).to eq('Updated Name')
      end
    end

    context 'with other user category' do
      let(:other_category) { create(:category, user: other_user) }

      it 'returns not found' do
        put "/api/v1/categories/#{other_category.id}", params: update_params, headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/categories/:id' do
    context 'category without tasks' do
      let(:category) { create(:category, user: user) }

      it 'deletes the category' do
        category_id = category.id

        expect {
          delete "/api/v1/categories/#{category_id}", headers: valid_headers
        }.to change(Category, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(Category.find_by(id: category_id)).to be_nil
      end
    end

    context 'category with tasks' do
      let(:category) { create(:category, user: user) }

      before do
        create(:task, user: user, category: category)
      end

      it 'prevents deletion and returns error' do
        expect {
          delete "/api/v1/categories/#{category.id}", headers: valid_headers
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to be_present
      end
    end

    context 'with other user category' do
      let(:other_category) { create(:category, user: other_user) }

      it 'returns not found' do
        delete "/api/v1/categories/#{other_category.id}", headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
