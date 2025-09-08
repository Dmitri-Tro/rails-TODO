FactoryBot.define do
  factory :task do
    association :user
    association :category
    sequence(:title) { |n| "Task #{n}" }
    description { "Описание задачи" }
    status { "pending" }
    priority { 3 }
    due_date { 1.week.from_now }

    trait :pending do
      status { "pending" }
    end

    trait :in_progress do
      status { "in_progress" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :high_priority do
      priority { 5 }
    end

    trait :low_priority do
      priority { 1 }
    end

    trait :overdue do
      due_date { 1.day.ago }
      status { "pending" }
    end

    trait :due_soon do
      due_date { 2.days.from_now }
      status { "pending" }
    end

    trait :with_tags do
      after(:create) do |task|
        tag1 = create(:tag, user: task.user, name: "Tag #{SecureRandom.hex(4)}")
        tag2 = create(:tag, user: task.user, name: "Tag #{SecureRandom.hex(4)}")
        create(:task_tag, task: task, tag: tag1)
        create(:task_tag, task: task, tag: tag2)
      end
    end

    trait :complete do
      with_tags
    end
  end
end
