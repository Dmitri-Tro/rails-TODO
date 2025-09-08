class Task < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags

  # Валидации
  validates :title, presence: { message: "не может быть пустым" },
                    length: { minimum: 3, maximum: 100, message: "должно содержать от 3 до 100 символов" }
  validates :description, length: { maximum: 1000, message: "не может превышать 1000 символов" }
  validates :status, inclusion: { in: %w[pending in_progress completed cancelled],
                                  message: "должен быть одним из: pending, in_progress, completed, cancelled" }
  validates :priority, inclusion: { in: 0..5, message: "должен быть от 0 до 5" }
  validates :due_date, presence: { message: "не может быть пустым" },
                       if: -> { status == "pending" || status == "in_progress" }

  # Scope методы
  scope :pending, -> { where(status: "pending") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :active, -> { where(status: [ "pending", "in_progress" ]) }
  scope :by_priority, ->(priority = nil) { priority ? where(priority: priority) : order(priority: :desc) }
  scope :high_priority, -> { where("priority >= ?", 4) }
  scope :overdue, -> { where("due_date < ? AND status != ?", Time.current, "completed") }
  scope :due_soon, -> { where("due_date BETWEEN ? AND ? AND status != ?",
                              Date.current, 1.week.from_now.to_date, "completed") }
  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :by_name, ->(name) { where("title ILIKE ? OR description ILIKE ?", "%#{name}%", "%#{name}%") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_due_date, -> { order(due_date: :asc) }

  # Callbacks
  before_validation :set_default_priority, if: :priority_changed?
  before_validation :set_default_status, if: :status_changed?

  # Методы
  def overdue?
    due_date.present? && due_date < Time.current && status != "completed"
  end

  def due_soon?
    due_date.present? && due_date.between?(Date.current, 1.week.from_now.to_date) && status != "completed"
  end

  def high_priority?
    priority >= 4
  end

  def can_complete?
    status == "pending" || status == "in_progress"
  end

  def can_cancel?
    status == "pending" || status == "in_progress"
  end

  def complete!
    update!(status: "completed") if can_complete?
  end

  def cancel!
    update!(status: "cancelled") if can_cancel?
  end

  def start_progress!
    update!(status: "in_progress") if status == "pending"
  end

  def days_until_due
    return nil unless due_date
    (due_date.to_date - Date.current).to_i
  end

  def priority_label
    case priority
    when 0 then "Низкий"
    when 1 then "Очень низкий"
    when 2 then "Низкий"
    when 3 then "Средний"
    when 4 then "Высокий"
    when 5 then "Критический"
    else "Неизвестно"
    end
  end

  def status_label
    case status
    when "pending" then "Ожидает"
    when "in_progress" then "В работе"
    when "completed" then "Завершено"
    when "cancelled" then "Отменено"
    else "Неизвестно"
    end
  end

  # API методы
  def to_api_json
    {
      id: id,
      title: title,
      description: description,
      status: status,
      status_label: status_label,
      priority: priority,
      priority_label: priority_label,
      due_date: due_date,
      days_until_due: days_until_due,
      overdue: overdue?,
      due_soon: due_soon?,
      high_priority: high_priority?,
      user_id: user_id,
      category: category&.to_api_json,
      tags: tags.map(&:to_api_json),
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def set_default_priority
    self.priority = 0 if priority.blank?
  end

  def set_default_status
    self.status = "pending" if status.blank?
  end
end
