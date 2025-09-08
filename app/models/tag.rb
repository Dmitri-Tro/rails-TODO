class Tag < ApplicationRecord
  belongs_to :user
  has_many :task_tags, dependent: :destroy
  has_many :tasks, through: :task_tags

  # Валидации
  validates :name, presence: { message: "не может быть пустым" },
                   length: { minimum: 2, maximum: 30, message: "должно содержать от 2 до 30 символов" }
  validates :name, uniqueness: { scope: :user_id, message: "уже существует для этого пользователя" }
  validates :color, presence: { message: "не может быть пустым" },
                    format: { with: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/,
                              message: "должен быть корректным HEX цветом" }

  # Scope методы
  scope :by_name, ->(name) { where("name ILIKE ?", "%#{name}%") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_task_count, -> { left_joins(:tasks).group(:id).order("COUNT(tasks.id) DESC") }
  scope :popular, -> { left_joins(:tasks).group(:id).having("COUNT(tasks.id) > 0").order("COUNT(tasks.id) DESC") }

  # Методы
  def tasks_count
    tasks.count
  end

  def active_tasks_count
    tasks.active.count
  end

  def completed_tasks_count
    tasks.completed.count
  end

  def overdue_tasks_count
    tasks.overdue.count
  end

  def has_tasks?
    tasks.exists?
  end

  def can_delete?
    !has_tasks?
  end

  def delete_safe
    if can_delete?
      destroy!
      true
    else
      errors.add(:base, "Нельзя удалить тег с задачами")
      false
    end
  end

  def usage_percentage
    return 0.0 if user.tasks.count.zero?
    ((tasks_count.to_f / user.tasks.count) * 100).round(1)
  end

  # API методы
  def to_api_json
    {
      id: id,
      name: name,
      color: color,
      tasks_count: tasks_count,
      active_tasks_count: active_tasks_count,
      completed_tasks_count: completed_tasks_count,
      overdue_tasks_count: overdue_tasks_count,
      has_tasks: has_tasks?,
      can_delete: can_delete?,
      usage_percentage: usage_percentage,
      user_id: user_id,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
