require 'rails_helper'

RSpec.describe TaskTag, type: :model do
  describe 'associations' do
    subject { build(:task_tag) }

    it { should belong_to(:task) }
    it { should belong_to(:tag) }
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:task) { create(:task, user: user) }
    let(:tag) { create(:tag, user: user) }

    it 'validates uniqueness of task_id scoped to tag_id' do
      create(:task_tag, task: task, tag: tag)
      duplicate = build(:task_tag, task: task, tag: tag)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:task_id]).to include('уже имеет этот тег')
    end

    it 'allows same task with different tags' do
      tag2 = create(:tag, user: user)
      create(:task_tag, task: task, tag: tag)
      new_task_tag = build(:task_tag, task: task, tag: tag2)

      expect(new_task_tag).to be_valid
    end

    it 'allows same tag with different tasks' do
      task2 = create(:task, user: user)
      create(:task_tag, task: task, tag: tag)
      new_task_tag = build(:task_tag, task: task2, tag: tag)

      expect(new_task_tag).to be_valid
    end
  end

  describe 'custom validations' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:task) { create(:task, user: user1) }
    let(:tag) { create(:tag, user: user2) }

    it 'validates that task and tag belong to the same user' do
      # Создаем TaskTag напрямую, минуя фабрику
      task_tag = TaskTag.new(task: task, tag: tag)

      expect(task_tag).not_to be_valid
      expect(task_tag.errors[:base]).to include('Задача и тег должны принадлежать одному пользователю')
    end

    it 'allows task and tag from same user' do
      tag.update!(user: user1)
      task_tag = build(:task_tag, task: task, tag: tag)

      expect(task_tag).to be_valid
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:task) { create(:task, user: user) }
    let(:tag) { create(:tag, user: user) }
    let(:task_tag) { create(:task_tag, task: task, tag: tag) }

    describe '#same_user?' do
      it 'returns true when task and tag belong to same user' do
        expect(task_tag.same_user?).to be true
      end

      it 'returns false when task and tag belong to different users' do
        other_user = create(:user)
        other_tag = create(:tag, user: other_user)
        # Создаем TaskTag напрямую, минуя валидации
        other_task_tag = TaskTag.new(task: task, tag: other_tag)
        expect(other_task_tag.same_user?).to be false
      end
    end
  end

  describe 'API methods' do
    let(:user) { create(:user) }
    let(:task) { create(:task, user: user) }
    let(:tag) { create(:tag, user: user) }
    let(:task_tag) { create(:task_tag, task: task, tag: tag) }

    describe '#to_api_json' do
      it 'returns a hash with task_tag data' do
        result = task_tag.to_api_json

        expect(result).to be_a(Hash)
        expect(result[:id]).to eq(task_tag.id)
        expect(result[:task_id]).to eq(task_tag.task_id)
        expect(result[:tag_id]).to eq(task_tag.tag_id)
        expect(result[:task]).to be_a(Hash)
        expect(result[:tag]).to be_a(Hash)
        expect(result[:created_at]).to eq(task_tag.created_at)
      end

      it 'includes task data' do
        result = task_tag.to_api_json

        expect(result[:task][:id]).to eq(task.id)
        expect(result[:task][:title]).to eq(task.title)
      end

      it 'includes tag data' do
        result = task_tag.to_api_json

        expect(result[:tag][:id]).to eq(tag.id)
        expect(result[:tag][:name]).to eq(tag.name)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:task_tag)).to be_valid
    end

    it 'creates valid associations' do
      task_tag = create(:task_tag)

      expect(task_tag.task).to be_valid
      expect(task_tag.tag).to be_valid
      expect(task_tag.task.user_id).to eq(task_tag.tag.user_id)
    end
  end
end
