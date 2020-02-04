require 'csv'
module Admin
  class CardBatchesController < Admin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = CardBatch.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   CardBatch.find_by!(slug: param)
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
    def create
      resource = resource_class.new(resource_params.except(:count))
      authorize_resource(resource)

      # Create the cards in batch as a transaction.
      num_cards_to_create = resource_params[:count]&.to_i
      ActiveRecord::Base.transaction do
        if resource.save && resource.generate_ids(num_cards_to_create)
          redirect_to(
            [namespace, resource],
            notice: translate_with_resource("create.success"),
          )
          return
        end
      end
    
      render :new, locals: {
        page: Administrate::Page::Form.new(dashboard, resource),
      }
    end

    def export
      card_batch_id = params[:card_batch_id].to_i
      card_batch = CardBatch.find(card_batch_id)
      @export = CSV.generate do |csv|
        rows = card_batch.cards.map do |card|
          [card.id, card.format_with_spaces]
        end
        rows.each { |row| csv << row }
        csv
      end

      send_data @export, filename: "card_export_#{card_batch_id}.csv"
    end
  end
end