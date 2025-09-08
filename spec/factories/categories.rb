FactoryBot.define do
  factory :category do
    association :user
    sequence(:name) { |n| "Category #{n}" }
    description { "Описание категории" }
    color { "#007bff" }

    trait :work do
      name { "Работа" }
      description { "Рабочие задачи" }
      color { "#dc3545" }
    end

    trait :personal do
      name { "Личное" }
      description { "Личные дела" }
      color { "#28a745" }
    end

    trait :study do
      name { "Учеба" }
      description { "Обучение и развитие" }
      color { "#17a2b8" }
    end

    trait :with_tasks do
      after(:create) do |category|
        create_list(:task, 2, category: category, user: category.user)
      end
    end
  end
end
