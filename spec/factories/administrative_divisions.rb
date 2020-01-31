FactoryBot.define do
  factory :administrative_division do
    name { Faker::Lorem.word.titleize }
    level { %w[first second third fourth].sample }
    code { (rand(9) + 0).to_s.rjust(2, '0') }

    trait :first do
      level { 'first' }
    end

    trait :second do
      level { 'second' }
      parent { create(:administrative_division, :first) }
    end

    trait :third do
      level { 'third' }
      parent { create(:administrative_division, :second) }
    end

    trait :fourth do
      level { 'fourth' }
      parent { create(:administrative_division, :third) }
    end
  end
end
