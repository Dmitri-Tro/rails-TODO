FactoryBot.define do
  factory :task_tag do
    association :task
    association :tag

    # Убеждаемся, что task и tag принадлежат одному пользователю
    after(:build) do |task_tag|
      if task_tag.task.user_id != task_tag.tag.user_id
        task_tag.tag.update!(user: task_tag.task.user)
      end
    end
  end
end
