FactoryBot.define do
  factory :simple_object do
    factory :simple_object_with_nonprofit do 
      nonprofit {create(:fv_poverty)}
    
      factory :simple_object_with_parent do
        parent { create(:simple_object, parent: create(:simple_object), )}

        factory :simple_object_with_friends_and_parent do
          friends {[create(:simple_object), create(:simple_object, parent: create(:simple_object))]} 
        end
      end
    end
  end
end
