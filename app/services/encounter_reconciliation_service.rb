require 'mergers/mergeable_encounter'
require 'mergers/mergeable_member'

class EncounterReconciliationService
  TRUSTED_ID_ROLE = 'identification'.freeze

  def reconcile!(encounter)
    return unless encounter_can_be_reconciled?(encounter)

    matching_encounters = fetch_matching_encounters(encounter)
    return unless enough_matching_encounters?(matching_encounters)

    mergeable_encounter = build_mergeable_encounter_if_reconcilable(matching_encounters)
    return if mergeable_encounter.nil?

    mergeable_member = build_mergeable_member_if_reconcilable(matching_encounters)
    return if mergeable_member.nil?

    mergeable_encounter.merge_and_dismiss_duplicates!
    mergeable_member.merge_and_archive_duplicates!
    mergeable_encounter.update_member!(mergeable_member.primary_member)
  end

  private

  def encounter_can_be_reconciled?(encounter)
    encounter.started? || encounter.prepared? || encounter.pending?
  end

  def enough_matching_encounters?(matching_encounters)
    matching_encounters.present? && matching_encounters.size >= 2
  end

  # Fetch all encounters that match membership number, provider, and date of service, including the given encounter.
  # Exclude all encounters that aren't being actively prepared or adjudicated
  #   - encounters that have left adjudication (approved, rejected, reimbursed)
  #   - encounters that are being edited by clients (returned)
  #   - encounters with dismissed id events
  #   - encounters with adjudication_state `revised` (they are earlier parts of a chain)
  def fetch_matching_encounters(encounter)
    return [] unless encounter.present?

    Encounter.joins(:member).joins(:identification_event)
             .where(members: { membership_number: encounter.member.membership_number })
             .where(provider: encounter.provider)
             .where("DATE_TRUNC(
                 'Day',
                 encounters.occurred_at::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.now.formatted_offset}'::INTERVAL
               ) = DATE_TRUNC(
                 'Day',
                 ?::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.now.formatted_offset}'::INTERVAL
               )", encounter.occurred_at)
             .where(reimbursement_id: nil)
             .where(adjudication_state: [nil, 'pending'])
             .where(identification_events: { dismissed: false }).to_a
  end

  # Identify which encounter should continue to be active, favoring a prepared claim.
  # Sort the rest to be marked as duplicates
  # Return nil if that state is not valid for reconciliation
  def build_mergeable_encounter_if_reconcilable(matching_encounters)
    return nil unless enough_matching_encounters?(matching_encounters)

    potential_primary_encounters = matching_encounters.reject(&:started?)
    potential_duplicate_encounters = matching_encounters - potential_primary_encounters
    return nil if potential_duplicate_encounters.empty? || potential_primary_encounters.size >= 2

    # If we don't have any selected potential primary encounters, we can pick one from the potential duplicates
    if potential_primary_encounters.empty?
      primary_encounter = potential_duplicate_encounters.first
      duplicate_encounters = potential_duplicate_encounters.drop(1)
    else
      primary_encounter = potential_primary_encounters.first
      duplicate_encounters = potential_duplicate_encounters
    end

    MergeableEncounter.new(primary_encounter, duplicate_encounters)
  end

  # Identify which member should continue to be active
  # Sort the rest to be marked as duplicates
  # Return nil if that state is not valid for reconciliation
  def build_mergeable_member_if_reconcilable(matching_encounters)
    return nil unless enough_matching_encounters?(matching_encounters)

    enrolled_member_encounters = matching_encounters.select { |e| e.member.enrolled? }
    enrolled_members = enrolled_member_encounters.map(&:member)
    duplicate_members = (matching_encounters - enrolled_member_encounters).map(&:member)

    trusted_enrolled_members = enrolled_member_encounters.select { |e| e.user.role == TRUSTED_ID_ROLE }.map(&:member)
    return nil if trusted_enrolled_members.empty? || enrolled_members.uniq.size > 1

    MergeableMember.new(trusted_enrolled_members.first, duplicate_members)
  end
end
