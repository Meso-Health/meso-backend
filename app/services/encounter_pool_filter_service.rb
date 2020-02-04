class EncounterPoolFilterService
  def filter_by_pool!(encounter)
    # If no pilot regions are configured, assume there is no pilot region and no
    # claims should be filtered.
    return unless encounter.pending? && PilotRegion.count.positive?

    # For now this only works if the member has a proper household and administrative_division
    # If not (such as manually created members) we have no way to check, so we won't mark them
    # as external. In the future we would change this spot to accomodate for manually created members
    household = encounter.member.household
    return if household.nil? || household.administrative_division.nil?

    # Return and do nothing if any of the administrative divisions are found in the pool
    return if administrative_division_is_in_pool?(household.administrative_division)

    # If we have reached this point, the member is outside the pool. Mark them as external
    encounter.adjudication_state = 'external'
    encounter.save!
  end

  def administrative_division_is_in_pool?(administrative_division)
    configured_admin_div_ids = PilotRegion.all.pluck(:administrative_division_id)
    all_administrative_divisions = AdministrativeDivision.find(configured_admin_div_ids).map(&:self_and_descendants).flatten
    all_administrative_divisions.include? administrative_division
  end
end
