class TaskTag < ApplicationRecord
  belongs_to :task
  belongs_to :tag

  # Валидации
  validates :task_id, uniqueness: { scope: :tag_id, message: "уже имеет этот тег" }
  validate :same_user_validation

  # Методы
  def same_user?
    task&.user_id == tag&.user_id
  end

  # API методы
  def to_api_json
    {
      id: id,
      task_id: task_id,
      tag_id: tag_id,
      task: task.to_api_json,
      tag: tag.to_api_json,
      created_at: created_at
    }
  end

  private

  def same_user_validation
    unless same_user?
      errors.add(:base, "Задача и тег должны принадлежать одному пользователю")
    end
  end
end
