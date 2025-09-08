FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    admin { false }

    trait :admin do
      admin { true }
    end

    trait :with_tasks do
      after(:create) do |user|
        create_list(:task, 3, user: user)
      end
    end

    trait :with_categories do
      after(:create) do |user|
        create_list(:category, 2, user: user)
      end
    end

    trait :with_tags do
      after(:create) do |user|
        create_list(:tag, 3, user: user)
      end
    end

    trait :complete do
      with_tasks
      with_categories
      with_tags
    end
  end
end
