class DiagnosesGroup < ApplicationRecord
  has_and_belongs_to_many :diagnoses
end
