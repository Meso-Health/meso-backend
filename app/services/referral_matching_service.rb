# Right now a referral is being matched to a single encounter which means
# as the encounter gets revised a new referral is being made and needs to be rematched
# this modeling doesn't quite reflect the reality that a single collection of revisions
# should only ever match up with one other single collection of revisions. Once the
# modelling for the difference between claim / revision_collection is cleared up we
# should also look to conform the referral matching system.
# One thing we lose out on is a true history because any encounter in the collection would
# refer only to the most recent referral which would not hold historical data about the revision
# of the referral itself.

class ReferralMatchingService
  def match_from_inbound_referral_date!(encounter)
    matching_encounter = Encounter.joins(:referrals)
                            .where(member_id: encounter.member_id)
                            .where(referrals: { date: encounter.inbound_referral_date })
                            .first

    return unless matching_encounter

    referral = Referral.where(encounter_id: matching_encounter.id).first
    previous_match = Encounter.where(referral_id: referral.id).first

    # we want to keep the first match unless it is from the same revision chain
    return unless !previous_match || previous_match.id == encounter.revised_encounter_id

    # if this is a new revision remove old link before adding new link
    if previous_match && previous_match.id == encounter.revised_encounter_id
      previous_match.referral_id = nil
      previous_match.save!
    end

    encounter.referral_id = referral.id
    encounter.save!
  end

  def match_from_referral!(continuation_referral)
    encounter_concluding_referral = Encounter.where(inbound_referral_date: continuation_referral.date)
                                        .order(:submitted_at)
                                        .first
    return unless encounter_concluding_referral != nil

    # if this is a resubmission we want to update to the new referral_id
    # otherwise we only want to save for encounters that haven't already been match
    # so that we don't overwrite previous matches.
    if encounter_concluding_referral.referral_id != nil
      previous_referral = Referral.find(encounter_concluding_referral.referral_id)
      previous_encounter = previous_referral.encounter
      current_encounter = continuation_referral.encounter
      if previous_encounter == current_encounter.revised_encounter
        encounter_concluding_referral.referral_id = continuation_referral.id
        encounter_concluding_referral.save!
      end
    else
      encounter_concluding_referral.referral_id = continuation_referral.id
      encounter_concluding_referral.save!
    end
  end

end
