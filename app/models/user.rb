class User < ApplicationRecord
  has_secure_password

  # Ассоциации
  has_many :tasks, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :tags, dependent: :destroy

  # Валидации
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "должен быть корректным email адресом" }
  validates :name, presence: true,
                   length: { minimum: 2, maximum: 50, message: "должно содержать от 2 до 50 символов" }
  validates :password, length: { minimum: 6, message: "должен содержать минимум 6 символов" },
                       if: -> { password.present? }

  # Scope методы
  scope :admins, -> { where(admin: true) }
  scope :regular_users, -> { where(admin: false) }

  # Методы
  def admin?
    admin == true
  end

  def tasks_count
    tasks.count
  end

  def completed_tasks_count
    tasks.completed.count
  end

  def pending_tasks_count
    tasks.pending.count
  end

  def overdue_tasks_count
    tasks.overdue.count
  end

  # API методы
  def to_api_json
    {
      id: id,
      email: email,
      name: name,
      admin: admin,
      tasks_count: tasks_count,
      completed_tasks_count: completed_tasks_count,
      pending_tasks_count: pending_tasks_count,
      overdue_tasks_count: overdue_tasks_count,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
