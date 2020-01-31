FactoryBot.define do
  factory :attachment do
    file { File.open(Rails.root.join("spec/factories/members/photo#{rand(12)+1}.jpg")) }

    after(:build) do |record|
      record.id = Attachment.digest(record.file.data)
    end
  end
end
