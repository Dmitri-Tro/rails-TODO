FactoryBot.define do
  factory :tag do
    association :user
    sequence(:name) { |n| "Tag #{n}" }
    color { "#6c757d" }

    trait :urgent do
      name { "Срочно" }
      color { "#dc3545" }
    end

    trait :important do
      name { "Важно" }
      color { "#ffc107" }
    end

    trait :idea do
      name { "Идея" }
      color { "#6f42c1" }
    end

    trait :with_tasks do
      after(:create) do |tag|
        create_list(:task, 2, user: tag.user).each do |task|
          create(:task_tag, task: task, tag: tag)
        end
      end
    end
  end
end
