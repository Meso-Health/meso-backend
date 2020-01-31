class MergeableEncounter
  attr_reader :primary_encounter
  attr_reader :duplicate_encounters

  def initialize(primary_encounter, duplicate_encounters)
    raise ArgumentError 'Must provide a primary encounter' unless primary_encounter.present?

    @primary_encounter = primary_encounter
    @duplicate_encounters = duplicate_encounters
  end

  def merge_and_dismiss_duplicates!
    return if @duplicate_encounters.blank?

    ActiveRecord::Base.transaction do
      @duplicate_encounters.each do |encounter|
        encounter.identification_event.dismiss_as_duplicate!
        encounter.save!
      end
    end
  end

  def update_member!(primary_member)
    ActiveRecord::Base.transaction do
      @primary_encounter.member = primary_member
      @primary_encounter.identification_event.member = primary_member
      @primary_encounter.save!
    end
  end
end
