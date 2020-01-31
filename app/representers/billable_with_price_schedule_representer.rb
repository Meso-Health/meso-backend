class BillableWithPriceScheduleRepresenter < BillableRepresenter
  property :active_price_schedule,
    writeable: false,
    render_nil: true,
    getter: ->(options:, **) { 
      PriceScheduleRepresenter.new(active_price_schedule_for_provider(options[:provider_id]))
    }
end
