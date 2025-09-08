require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:category).optional }
    it { should have_many(:task_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:task_tags) }
  end

  describe 'validations' do
    subject { build(:task) }

    it 'validates presence of title' do
      task = build(:task, title: '')
      expect(task).not_to be_valid
      expect(task.errors[:title]).to include('не может быть пустым')
    end

    it 'validates length of title' do
      task = build(:task, title: 'xx')
      expect(task).not_to be_valid
      expect(task.errors[:title]).to include('должно содержать от 3 до 100 символов')
    end

    it 'validates length of description' do
      task = build(:task, description: 'x' * 1001)
      expect(task).not_to be_valid
      expect(task.errors[:description]).to include('не может превышать 1000 символов')
    end

    it 'validates inclusion of status' do
      task = build(:task, status: 'invalid_status')
      expect(task).not_to be_valid
      expect(task.errors[:status]).to include('должен быть одним из: pending, in_progress, completed, cancelled')
    end

    it 'validates inclusion of priority' do
      task = build(:task, priority: 6)
      expect(task).not_to be_valid
      expect(task.errors[:priority]).to include('должен быть от 0 до 5')
    end
  end

  describe 'conditional validations' do
    let(:user) { create(:user) }
    let(:category) { create(:category, user: user) }

    context 'when status is pending or in_progress' do
      it 'requires due_date' do
        task = build(:task, user: user, category: category, status: 'pending', due_date: nil)
        expect(task).not_to be_valid
        expect(task.errors[:due_date]).to include('не может быть пустым')
      end
    end

    context 'when status is completed or cancelled' do
      it 'does not require due_date' do
        task = build(:task, user: user, category: category, status: 'completed', due_date: nil)
        expect(task).to be_valid
      end
    end
  end

  describe 'scope methods' do
    let(:user) { create(:user) }
    let(:category) { create(:category, user: user) }

    let!(:pending_task) { create(:task, :pending, user: user, category: category) }
    let!(:in_progress_task) { create(:task, :in_progress, user: user, category: category) }
    let!(:completed_task) { create(:task, :completed, user: user, category: category) }
    let!(:cancelled_task) { create(:task, :cancelled, user: user, category: category) }
    let!(:high_priority_task) { create(:task, :high_priority, user: user, category: category) }
    let!(:overdue_task) { create(:task, :overdue, user: user, category: category) }
    let!(:due_soon_task) { create(:task, :due_soon, user: user, category: category) }

    describe '.pending' do
      it 'returns only pending tasks' do
        expect(Task.pending).to include(pending_task)
        expect(Task.pending).not_to include(in_progress_task, completed_task, cancelled_task)
      end
    end

    describe '.in_progress' do
      it 'returns only in_progress tasks' do
        expect(Task.in_progress).to include(in_progress_task)
        expect(Task.in_progress).not_to include(pending_task, completed_task, cancelled_task)
      end
    end

    describe '.completed' do
      it 'returns only completed tasks' do
        expect(Task.completed).to include(completed_task)
        expect(Task.completed).not_to include(pending_task, in_progress_task, cancelled_task)
      end
    end

    describe '.cancelled' do
      it 'returns only cancelled tasks' do
        expect(Task.cancelled).to include(cancelled_task)
        expect(Task.cancelled).not_to include(pending_task, in_progress_task, completed_task)
      end
    end

    describe '.active' do
      it 'returns pending and in_progress tasks' do
        expect(Task.active).to include(pending_task, in_progress_task)
        expect(Task.active).not_to include(completed_task, cancelled_task)
      end
    end

    describe '.high_priority' do
      it 'returns only high priority tasks' do
        expect(Task.high_priority).to include(high_priority_task)
        expect(Task.high_priority).not_to include(pending_task)
      end
    end

    describe '.overdue' do
      it 'returns only overdue tasks' do
        expect(Task.overdue).to include(overdue_task)
        expect(Task.overdue).not_to include(pending_task, due_soon_task)
      end
    end

    describe '.due_soon' do
      it 'returns only due soon tasks' do
        expect(Task.due_soon).to include(due_soon_task)
        expect(Task.due_soon).not_to include(pending_task, overdue_task)
      end
    end

    describe '.by_category' do
      it 'returns tasks by category' do
        expect(Task.by_category(category.id)).to include(pending_task, in_progress_task)
      end
    end

    describe '.recent' do
      it 'returns tasks ordered by creation date' do
        expect(Task.recent.first).to eq(due_soon_task)
      end
    end

    describe '.by_due_date' do
      it 'returns tasks ordered by due date' do
        expect(Task.by_due_date.first).to eq(overdue_task)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:category) { create(:category, user: user) }
    let(:task) { create(:task, user: user, category: category) }

    describe '#overdue?' do
      it 'returns true for overdue tasks' do
        overdue_task = create(:task, :overdue, user: user, category: category)
        expect(overdue_task.overdue?).to be true
      end

      it 'returns false for non-overdue tasks' do
        expect(task.overdue?).to be false
      end

      it 'returns false for completed tasks' do
        completed_task = create(:task, :completed, user: user, category: category, due_date: 1.day.ago)
        expect(completed_task.overdue?).to be false
      end
    end

    describe '#due_soon?' do
      it 'returns true for due soon tasks' do
        due_soon_task = create(:task, :due_soon, user: user, category: category)
        expect(due_soon_task.due_soon?).to be true
      end

      it 'returns false for non-due soon tasks' do
        expect(task.due_soon?).to be false
      end
    end

    describe '#high_priority?' do
      it 'returns true for high priority tasks' do
        high_priority_task = create(:task, :high_priority, user: user, category: category)
        expect(high_priority_task.high_priority?).to be true
      end

      it 'returns false for low priority tasks' do
        expect(task.high_priority?).to be false
      end
    end

    describe '#can_complete?' do
      it 'returns true for pending tasks' do
        expect(task.can_complete?).to be true
      end

      it 'returns true for in_progress tasks' do
        in_progress_task = create(:task, :in_progress, user: user, category: category)
        expect(in_progress_task.can_complete?).to be true
      end

      it 'returns false for completed tasks' do
        completed_task = create(:task, :completed, user: user, category: category)
        expect(completed_task.can_complete?).to be false
      end
    end

    describe '#complete!' do
      it 'changes status to completed' do
        task.complete!
        expect(task.reload.status).to eq('completed')
      end

      it 'does not change status if cannot complete' do
        completed_task = create(:task, :completed, user: user, category: category)
        completed_task.complete!
        expect(completed_task.reload.status).to eq('completed')
      end
    end

    describe '#cancel!' do
      it 'changes status to cancelled' do
        task.cancel!
        expect(task.reload.status).to eq('cancelled')
      end
    end

    describe '#start_progress!' do
      it 'changes status to in_progress' do
        task.start_progress!
        expect(task.reload.status).to eq('in_progress')
      end

      it 'does not change status if not pending' do
        in_progress_task = create(:task, :in_progress, user: user, category: category)
        in_progress_task.start_progress!
        expect(in_progress_task.reload.status).to eq('in_progress')
      end
    end

        describe '#days_until_due' do
      it 'returns correct number of days' do
        task.update!(due_date: 5.days.from_now)
        expect(task.days_until_due).to eq(5)
      end

      it 'returns nil if no due date' do
        task.update!(status: 'completed', due_date: nil)
        expect(task.days_until_due).to be_nil
      end
    end

    describe '#priority_label' do
      it 'returns correct priority labels' do
        expect(create(:task, priority: 0, user: user, category: category).priority_label).to eq('Низкий')
        expect(create(:task, priority: 3, user: user, category: category).priority_label).to eq('Средний')
        expect(create(:task, priority: 5, user: user, category: category).priority_label).to eq('Критический')
      end
    end

    describe '#status_label' do
      it 'returns correct status labels' do
        expect(create(:task, status: 'pending', user: user, category: category).status_label).to eq('Ожидает')
        expect(create(:task, status: 'in_progress', user: user, category: category).status_label).to eq('В работе')
        expect(create(:task, status: 'completed', user: user, category: category).status_label).to eq('Завершено')
      end
    end
  end

  describe 'callbacks' do
    let(:user) { create(:user) }
    let(:category) { create(:category, user: user) }

    it 'sets default priority to 0' do
      task = create(:task, user: user, category: category, priority: nil)
      expect(task.priority).to eq(0)
    end

    it 'sets default status to pending' do
      task = create(:task, user: user, category: category, status: nil)
      expect(task.status).to eq('pending')
    end
  end

  describe 'API methods' do
    let(:user) { create(:user) }
    let(:category) { create(:category, user: user) }
    let(:task) { create(:task, :complete, user: user, category: category) }

    describe '#to_api_json' do
      it 'returns a hash with task data' do
        result = task.to_api_json

        expect(result).to be_a(Hash)
        expect(result[:id]).to eq(task.id)
        expect(result[:title]).to eq(task.title)
        expect(result[:status]).to eq(task.status)
        expect(result[:status_label]).to eq(task.status_label)
        expect(result[:priority]).to eq(task.priority)
        expect(result[:priority_label]).to eq(task.priority_label)
        expect(result[:overdue]).to eq(task.overdue?)
        expect(result[:due_soon]).to eq(task.due_soon?)
        expect(result[:high_priority]).to eq(task.high_priority?)
        expect(result[:user_id]).to eq(task.user_id)
        expect(result[:category]).to be_a(Hash)
        expect(result[:tags]).to be_an(Array)
        expect(result[:created_at]).to eq(task.created_at)
        expect(result[:updated_at]).to eq(task.updated_at)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:task)).to be_valid
    end

    it 'has valid status trait factories' do
      expect(build(:task, :pending)).to be_valid
      expect(build(:task, :in_progress)).to be_valid
      expect(build(:task, :completed)).to be_valid
      expect(build(:task, :cancelled)).to be_valid
    end

    it 'has valid priority trait factories' do
      expect(build(:task, :high_priority)).to be_valid
      expect(build(:task, :low_priority)).to be_valid
    end
  end
end
