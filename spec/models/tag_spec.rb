require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:task_tags).dependent(:destroy) }
    it { should have_many(:tasks).through(:task_tags) }
  end

  describe 'validations' do
    subject { build(:tag) }

    it 'validates presence of name' do
      tag = build(:tag, name: '')
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include('не может быть пустым')
    end

    it 'validates length of name' do
      tag = build(:tag, name: 'x')
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include('должно содержать от 2 до 30 символов')
    end

    it 'validates presence of color' do
      tag = build(:tag, color: '')
      expect(tag).not_to be_valid
      expect(tag.errors[:color]).to include('не может быть пустым')
    end
  end

  describe 'uniqueness validation' do
    let(:user) { create(:user) }
    let!(:existing_tag) { create(:tag, user: user, name: 'Important') }

    it 'allows same name for different users' do
      other_user = create(:user)
      new_tag = build(:tag, user: other_user, name: 'Important')
      expect(new_tag).to be_valid
    end

    it 'prevents duplicate names for same user' do
      duplicate_tag = build(:tag, user: user, name: 'Important')
      expect(duplicate_tag).not_to be_valid
      expect(duplicate_tag.errors[:name]).to include('уже существует для этого пользователя')
    end
  end

  describe 'color format validation' do
    let(:user) { create(:user) }

    it 'accepts valid HEX colors' do
      valid_colors = [
        '#6c757d',
        '#dc3545',
        '#ffc107',
        '#6f42c1',
        '#fff',
        '#000'
      ]

      valid_colors.each do |color|
        tag = build(:tag, user: user, color: color)
        expect(tag).to be_valid
      end
    end

    it 'rejects invalid HEX colors' do
      invalid_colors = [
        'red',
        '#gggggg',
        '#12345',
        '6c757d',
        '#'
      ]

      invalid_colors.each do |color|
        tag = build(:tag, user: user, color: color)
        expect(tag).not_to be_valid
        expect(tag.errors[:color]).to include('должен быть корректным HEX цветом')
      end
    end
  end

  describe 'scope methods' do
    let(:user) { create(:user) }
    let!(:tag1) { create(:tag, user: user, name: 'Urgent') }
    let!(:tag2) { create(:tag, user: user, name: 'Important') }
    let!(:tag3) { create(:tag, user: user, name: 'Idea') }

    describe '.by_name' do
      it 'finds tags by name' do
        expect(Tag.by_name('Urgent')).to include(tag1)
        expect(Tag.by_name('urgent')).to include(tag1) # case insensitive
        expect(Tag.by_name('Important')).to include(tag2)
      end
    end

    describe '.recent' do
      it 'returns tags ordered by creation date' do
        expect(Tag.recent.first).to eq(tag3)
      end
    end

    describe '.by_task_count' do
      it 'returns tags ordered by task count' do
        create(:task, user: user).tags << tag1
        create(:task, user: user).tags << tag1
        create(:task, user: user).tags << tag2

        expect(Tag.by_task_count.first).to eq(tag1)
        expect(Tag.by_task_count.second).to eq(tag2)
        expect(Tag.by_task_count.third).to eq(tag3)
      end
    end

    describe '.popular' do
      it 'returns only tags with tasks' do
        create(:task, user: user).tags << tag1
        create(:task, user: user).tags << tag2

        expect(Tag.popular).to include(tag1, tag2)
        expect(Tag.popular).not_to include(tag3)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:tag) { create(:tag, user: user) }

    describe '#tasks_count' do
      it 'returns correct count' do
        expect(tag.tasks_count).to eq(0)
        create(:task, user: user).tags << tag
        expect(tag.tasks_count).to eq(1)
      end
    end

    describe '#active_tasks_count' do
      it 'returns count of active tasks' do
        task1 = create(:task, :pending, user: user)
        task2 = create(:task, :in_progress, user: user)
        task3 = create(:task, :completed, user: user)

        task1.tags << tag
        task2.tags << tag
        task3.tags << tag

        expect(tag.active_tasks_count).to eq(2)
      end
    end

    describe '#completed_tasks_count' do
      it 'returns count of completed tasks' do
        task1 = create(:task, :pending, user: user)
        task2 = create(:task, :completed, user: user)

        task1.tags << tag
        task2.tags << tag

        expect(tag.completed_tasks_count).to eq(1)
      end
    end

    describe '#overdue_tasks_count' do
      it 'returns count of overdue tasks' do
        task1 = create(:task, :overdue, user: user)
        task2 = create(:task, :pending, user: user)

        task1.tags << tag
        task2.tags << tag

        expect(tag.overdue_tasks_count).to eq(1)
      end
    end

    describe '#has_tasks?' do
      it 'returns true when tag has tasks' do
        expect(tag.has_tasks?).to be false
        create(:task, user: user).tags << tag
        expect(tag.has_tasks?).to be true
      end
    end

    describe '#can_delete?' do
      it 'returns true when tag has no tasks' do
        expect(tag.can_delete?).to be true
      end

      it 'returns false when tag has tasks' do
        create(:task, user: user).tags << tag
        expect(tag.can_delete?).to be false
      end
    end

        describe '#delete_safe' do
      it 'deletes tag when it has no tasks' do
        result = tag.delete_safe
        expect(result).to be true
        expect(Tag.exists?(tag.id)).to be false
      end

      it 'does not delete tag when it has tasks' do
        create(:task, user: user).tags << tag
        result = tag.delete_safe
        expect(result).to be false
        expect(Tag.exists?(tag.id)).to be true
        expect(tag.errors[:base]).to include('Нельзя удалить тег с задачами')
      end
    end

    describe '#usage_percentage' do
      it 'returns correct usage percentage' do
        create(:task, user: user).tags << tag
        create(:task, user: user).tags << tag

        expect(tag.usage_percentage).to eq(100.0)
      end

      it 'returns 0 when user has no tasks' do
        expect(tag.usage_percentage).to eq(0.0)
      end
    end
  end

  describe 'API methods' do
    let(:user) { create(:user) }
    let(:tag) { create(:tag, user: user) }

    describe '#to_api_json' do
      it 'returns a hash with tag data' do
        result = tag.to_api_json

        expect(result).to be_a(Hash)
        expect(result[:id]).to eq(tag.id)
        expect(result[:name]).to eq(tag.name)
        expect(result[:color]).to eq(tag.color)
        expect(result[:tasks_count]).to eq(0)
        expect(result[:active_tasks_count]).to eq(0)
        expect(result[:completed_tasks_count]).to eq(0)
        expect(result[:overdue_tasks_count]).to eq(0)
        expect(result[:has_tasks]).to be false
        expect(result[:can_delete]).to be true
        expect(result[:usage_percentage]).to eq(0.0)
        expect(result[:user_id]).to eq(tag.user_id)
        expect(result[:created_at]).to eq(tag.created_at)
        expect(result[:updated_at]).to eq(tag.updated_at)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:tag)).to be_valid
    end

    it 'has valid trait factories' do
      expect(build(:tag, :urgent)).to be_valid
      expect(build(:tag, :important)).to be_valid
      expect(build(:tag, :idea)).to be_valid
    end

    it 'has valid with_tasks trait' do
      tag = create(:tag, :with_tasks)
      expect(tag.tasks_count).to eq(2)
    end
  end
end
