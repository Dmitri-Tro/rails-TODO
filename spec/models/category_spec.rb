require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:tasks).dependent(:nullify) }
  end

  describe 'validations' do
    subject { build(:category) }

    it 'validates presence of name' do
      category = build(:category, name: '')
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include('не может быть пустым')
    end

    it 'validates length of name' do
      category = build(:category, name: 'x')
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include('должно содержать от 2 до 50 символов')
    end

    it 'validates length of description' do
      category = build(:category, description: 'x' * 501)
      expect(category).not_to be_valid
      expect(category.errors[:description]).to include('не может превышать 500 символов')
    end

    it 'validates presence of color' do
      category = build(:category, color: '')
      expect(category).not_to be_valid
      expect(category.errors[:color]).to include('не может быть пустым')
    end
  end

  describe 'uniqueness validation' do
    let(:user) { create(:user) }
    let!(:existing_category) { create(:category, user: user, name: 'Work') }

    it 'allows same name for different users' do
      other_user = create(:user)
      new_category = build(:category, user: other_user, name: 'Work')
      expect(new_category).to be_valid
    end

    it 'prevents duplicate names for same user' do
      duplicate_category = build(:category, user: user, name: 'Work')
      expect(duplicate_category).not_to be_valid
      expect(duplicate_category.errors[:name]).to include('уже существует для этого пользователя')
    end
  end

  describe 'color format validation' do
    let(:user) { create(:user) }

    it 'accepts valid HEX colors' do
      valid_colors = [
        '#007bff',
        '#dc3545',
        '#28a745',
        '#ffc107',
        '#6f42c1',
        '#fff',
        '#000'
      ]

      valid_colors.each do |color|
        category = build(:category, user: user, color: color)
        expect(category).to be_valid
      end
    end

    it 'rejects invalid HEX colors' do
      invalid_colors = [
        'red',
        '#gggggg',
        '#12345',
        '007bff',
        '#'
      ]

      invalid_colors.each do |color|
        category = build(:category, user: user, color: color)
        expect(category).not_to be_valid
        expect(category.errors[:color]).to include('должен быть корректным HEX цветом')
      end
    end
  end

  describe 'scope methods' do
    let(:user) { create(:user) }
    let!(:category1) { create(:category, user: user, name: 'Work') }
    let!(:category2) { create(:category, user: user, name: 'Personal') }
    let!(:category3) { create(:category, user: user, name: 'Study') }

    describe '.by_name' do
      it 'finds categories by name' do
        expect(Category.by_name('Work')).to include(category1)
        expect(Category.by_name('work')).to include(category1) # case insensitive
        expect(Category.by_name('Personal')).to include(category2)
      end
    end

    describe '.recent' do
      it 'returns categories ordered by creation date' do
        expect(Category.recent.first).to eq(category3)
      end
    end

    describe '.by_task_count' do
      it 'returns categories ordered by task count' do
        create(:task, user: user, category: category1)
        create(:task, user: user, category: category1)
        create(:task, user: user, category: category2)

        expect(Category.by_task_count.first).to eq(category1)
        expect(Category.by_task_count.second).to eq(category2)
        expect(Category.by_task_count.third).to eq(category3)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:category) { create(:category, user: user) }

    describe '#tasks_count' do
      it 'returns correct count' do
        expect(category.tasks_count).to eq(0)
        create(:task, user: user, category: category)
        expect(category.tasks_count).to eq(1)
      end
    end

    describe '#active_tasks_count' do
      it 'returns count of active tasks' do
        create(:task, :pending, user: user, category: category)
        create(:task, :in_progress, user: user, category: category)
        create(:task, :completed, user: user, category: category)

        expect(category.active_tasks_count).to eq(2)
      end
    end

    describe '#completed_tasks_count' do
      it 'returns count of completed tasks' do
        create(:task, :pending, user: user, category: category)
        create(:task, :completed, user: user, category: category)

        expect(category.completed_tasks_count).to eq(1)
      end
    end

    describe '#overdue_tasks_count' do
      it 'returns count of overdue tasks' do
        create(:task, :overdue, user: user, category: category)
        create(:task, :pending, user: user, category: category)

        expect(category.overdue_tasks_count).to eq(1)
      end
    end

    describe '#has_tasks?' do
      it 'returns true when category has tasks' do
        expect(category.has_tasks?).to be false
        create(:task, user: user, category: category)
        expect(category.has_tasks?).to be true
      end
    end

    describe '#can_delete?' do
      it 'returns true when category has no tasks' do
        expect(category.can_delete?).to be true
      end

      it 'returns false when category has tasks' do
        create(:task, user: user, category: category)
        expect(category.can_delete?).to be false
      end
    end

        describe '#delete_safe' do
      it 'deletes category when it has no tasks' do
        result = category.delete_safe
        expect(result).to be true
        expect(Category.exists?(category.id)).to be false
      end

      it 'does not delete category when it has tasks' do
        create(:task, user: user, category: category)
        result = category.delete_safe
        expect(result).to be false
        expect(Category.exists?(category.id)).to be true
        expect(category.errors[:base]).to include('Нельзя удалить категорию с задачами')
      end
    end
  end

  describe 'API methods' do
    let(:user) { create(:user) }
    let(:category) { create(:category, user: user) }

    describe '#to_api_json' do
      it 'returns a hash with category data' do
        result = category.to_api_json

        expect(result).to be_a(Hash)
        expect(result[:id]).to eq(category.id)
        expect(result[:name]).to eq(category.name)
        expect(result[:description]).to eq(category.description)
        expect(result[:color]).to eq(category.color)
        expect(result[:tasks_count]).to eq(0)
        expect(result[:active_tasks_count]).to eq(0)
        expect(result[:completed_tasks_count]).to eq(0)
        expect(result[:overdue_tasks_count]).to eq(0)
        expect(result[:has_tasks]).to be false
        expect(result[:can_delete]).to be true
        expect(result[:user_id]).to eq(category.user_id)
        expect(result[:created_at]).to eq(category.created_at)
        expect(result[:updated_at]).to eq(category.updated_at)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:category)).to be_valid
    end

    it 'has valid trait factories' do
      expect(build(:category, :work)).to be_valid
      expect(build(:category, :personal)).to be_valid
      expect(build(:category, :study)).to be_valid
    end

    it 'has valid with_tasks trait' do
      category = create(:category, :with_tasks)
      expect(category.tasks_count).to eq(2)
    end
  end
end
