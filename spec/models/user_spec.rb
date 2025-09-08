require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:tasks).dependent(:destroy) }
    it { should have_many(:categories).dependent(:destroy) }
    it { should have_many(:tags).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it 'validates presence of email' do
      user = build(:user, email: '')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'validates presence of name' do
      user = build(:user, name: '')
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of email' do
      existing_user = create(:user)
      user = build(:user, email: existing_user.email)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('has already been taken')
    end

    it 'validates length of name' do
      user = build(:user, name: 'x')
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include('должно содержать от 2 до 50 символов')
    end

    it 'validates length of password' do
      user = build(:user, password: 'xxxxx')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('должен содержать минимум 6 символов')
    end
  end

  describe 'email format validation' do
    let(:user) { build(:user) }

    it 'accepts valid email addresses' do
      valid_emails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org'
      ]

      valid_emails.each do |email|
        user.email = email
        expect(user).to be_valid
      end
    end

    it 'rejects invalid email addresses' do
      invalid_emails = [
        'invalid-email',
        '@example.com',
        'user@',
        'user@.com'
      ]

      invalid_emails.each do |email|
        user.email = email
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('должен быть корректным email адресом')
      end
    end
  end

  describe 'password validation' do
    let(:user) { build(:user, password: nil) }

    it 'requires password on create' do
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'allows password update with valid length' do
      user.password = 'newpass'
      expect(user).to be_valid
    end

    it 'rejects short passwords' do
      user.password = '12345'
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('должен содержать минимум 6 символов')
    end
  end

  describe 'scope methods' do
    let!(:admin_user) { create(:user, :admin) }
    let!(:regular_user) { create(:user) }

    describe '.admins' do
      it 'returns only admin users' do
        expect(User.admins).to include(admin_user)
        expect(User.admins).not_to include(regular_user)
      end
    end

    describe '.regular_users' do
      it 'returns only regular users' do
        expect(User.regular_users).to include(regular_user)
        expect(User.regular_users).not_to include(admin_user)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user, :complete) }

    describe '#admin?' do
      it 'returns true for admin users' do
        admin_user = create(:user, :admin)
        expect(admin_user.admin?).to be true
      end

      it 'returns false for regular users' do
        expect(user.admin?).to be false
      end
    end

    describe '#tasks_count' do
      it 'returns the correct count of tasks' do
        expect(user.tasks_count).to eq(3)
      end
    end

    describe '#completed_tasks_count' do
      it 'returns the correct count of completed tasks' do
        user.tasks.first.update!(status: 'completed')
        expect(user.completed_tasks_count).to eq(1)
      end
    end

    describe '#pending_tasks_count' do
      it 'returns the correct count of pending tasks' do
        expect(user.pending_tasks_count).to eq(3)
      end
    end

    describe '#overdue_tasks_count' do
      it 'returns the correct count of overdue tasks' do
        user.tasks.first.update!(due_date: 1.day.ago, status: 'pending')
        expect(user.overdue_tasks_count).to eq(1)
      end
    end
  end

  describe 'API methods' do
    let(:user) { create(:user, :complete) }

    describe '#to_api_json' do
      it 'returns a hash with user data' do
        result = user.to_api_json

        expect(result).to be_a(Hash)
        expect(result[:id]).to eq(user.id)
        expect(result[:email]).to eq(user.email)
        expect(result[:name]).to eq(user.name)
        expect(result[:admin]).to eq(user.admin)
        expect(result[:tasks_count]).to eq(3)
        expect(result[:completed_tasks_count]).to eq(0)
        expect(result[:pending_tasks_count]).to eq(3)
        expect(result[:overdue_tasks_count]).to eq(0)
        expect(result[:created_at]).to eq(user.created_at)
        expect(result[:updated_at]).to eq(user.updated_at)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end

    it 'has a valid admin factory' do
      expect(build(:user, :admin)).to be_valid
    end

    it 'has a valid complete factory' do
      expect(build(:user, :complete)).to be_valid
    end
  end
end
