class EncounterRepresenter < ApplicationRepresenter
  property :id,
           skip_parse: ->(**) { persisted? },
           setter: lambda { |fragment:, represented:, **|
             represented.id = fragment
             represented.claim_id = fragment
           }
  property :provider_id, writeable: false
  property :member_id, skip_parse: ->(**) { persisted? }
  property :identification_event_id, skip_parse: ->(**) { persisted? }, render_nil: true
  property :claim_id
  property :user_id
  property :updated_at, writeable: false

  property :created_at, writeable: false
  property :occurred_at
  property :backdated_occurred_at
  property :prepared_at, getter: ->(**) { prepared_at || created_at }
  property :submitted_at, getter: ->(**) { submitted_at || created_at }
  property :submission_state

  property :adjudication_state, render_nil: true
  property :adjudicator_id, render_nil: true
  property :adjudicated_at, render_nil: true

  # adjudication_reason is a derived field that existing android clients will use when fetching returned claims.
  property :adjudication_reason, render_nil: true, writeable: false
  property :adjudication_reason_category, render_nil: true
  property :adjudication_comment, render_nil: true
  property :revised_encounter_id, render_nil: true
  property :resubmitted, getter: ->(**) { resubmitted? }, writeable: false
  property :submitter_name, writeable: false, getter: ->(**) { user&.name }
  property :adjudicator_name, writeable: false, getter: ->(**) { adjudicator&.name }, render_nil: true
  property :auditor_name, writeable: false, getter: ->(**) { auditor&.name }, render_nil: true

  property :visit_type, render_nil: true
  property :discharge_date, render_nil: true
  property :visit_reason, render_nil: true
  property :inbound_referral_date, render_nil: true
  property :patient_outcome, render_nil: true
  property :provider_comment, render_nil: true
  property :price, writeable: false

  property :member_unconfirmed, getter: ->(**) { member_unconfirmed? }, writeable: false
  property :member_inactive_at_time_of_service, getter: ->(**) { member_inactive_at_time_of_service? }, writeable: false
  property :inbound_referral_unlinked, getter: ->(**) { inbound_referral_unlinked? }, writeable: false

  collection :billables, decorator: BillableRepresenter, writeable: false
  collection :price_schedules,
             decorator: PriceScheduleRepresenter,
             writeable: false,
             getter: ->(**) { price_schedules_with_previous }
  collection :encounter_items,
             decorator: EncounterItemRepresenter,
             instance: ->(represented:, fragment:, **) { EncounterItem.find_by(id: fragment['id']) || EncounterItem.new(encounter: represented) }
  property :referral,
           as: :inbound_referral,
           decorator: ReferralRepresenter
  collection :referrals,
             decorator: ReferralRepresenter,
             instance: ->(represented:, fragment:, **) { Referral.find_by(id: fragment['id']) || Referral.new(encounter: represented) }
  property :diagnosis_ids
  collection :diagnoses, decorator: DiagnosisRepresenter, writeable: false

  property :auditor_id
  property :audited_at

  property :reimbursement_id, skip_parse: ->(**) { persisted? }, render_nil: true
  property :reimbursement_created_at,
           getter: ->(**) { reimbursement&.created_at },
           writeable: false,
           render_nil: true
  property :reimbursement_completed_at,
           getter: ->(**) { reimbursement&.completed_at },
           writeable: false,
           render_nil: true
  property :reimbursal_amount, writeable: false
  property :custom_reimbursal_amount, readable: false

  # Uganda-specific
  property :clinic_number, getter: ->(**) { identification_event&.clinic_number }, render_nil: true, writeable: false
  property :clinic_number_type, getter: ->(**) { identification_event&.clinic_number_type }, render_nil: true, writeable: false
  property :has_fever, skip_parse: ->(**) { persisted? }, render_nil: true
  property :forms, setter: ->(input:, **) { input.each { |i| add_form(i) } }, readable: false
  property :form_urls, exec_context: :decorator, writeable: false
  property :copayment_amount

  def form_urls
    return nil if decorated.forms.empty?
    decorated.forms.map do |form|
      form.convert('-strip').thumb('1080x1080').url if form.stored?
    end
  end
end
