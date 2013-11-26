FactoryGirl.define do
  factory :pool do
    trait :active do
      active true
    end

    trait :inactive do
      active false
    end

    trait :unexpired do
      end_date DateTime.now.to_date + 1.days
    end

    trait :expired do
      end_date DateTime.now.to_date
    end

    trait :expiring_soon do
      end_date DateTime.now.to_date + 120
    end

    trait :not_expiring_soon do
      end_date DateTime.now.to_date + 121
    end
  end
end
