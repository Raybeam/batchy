FactoryGirl.define do
  factory :batch, :class => Batchy::Batch do
    name 'Bob'

    trait :attached_guid do
      guid 'BlahClass::3'
    end

    factory :batch_with_guid, :traits => [:attached_guid]
  end
end