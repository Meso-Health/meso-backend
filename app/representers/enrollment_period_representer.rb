class EnrollmentPeriodRepresenter < ApplicationRepresenter
  property :id, writeable: false
  property :administrative_division_id, writeable: false
  property :start_date, writeable: false
  property :end_date, writeable: false
  property :coverage_start_date, writeable: false
  property :coverage_end_date, writeable: false
end
