module HasAttachments
  extend ActiveSupport::Concern

  class_methods do
    def has_attachments(attribute)
      association_name = "#{attribute.to_s.singularize}_attachments".to_sym
      has_and_belongs_to_many association_name, class_name: 'Attachment'

      scope "preload_#{attribute}".to_sym, -> { includes(association_name) }

      instance_methods = Module.new do
        define_method attribute do
          attachments = send(association_name)
          attachments.compact.map(&:file)
        end

        define_method "add_#{attribute.to_s.singularize}" do |value|
          to_add = begin
            if Dragonfly::Model::Attachment === value || Dragonfly::Job === value
              Attachment.from_data(value.data)
            elsif String === value || value.respond_to?(:read)
              Attachment.from_data(value)
            else
              value
            end
          end

          transaction do
            unless send(association_name).exists?(to_add.try(:id))
              send(association_name) << to_add
            end
          end
        end

        define_method "any_#{attribute}_stored?" do
          attachments = send(association_name)
          attachments.compact.any?(&:file_stored?)
        end
      end

      include instance_methods
    end
  end
end
