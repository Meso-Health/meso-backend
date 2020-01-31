module HasAttachment
  extend ActiveSupport::Concern

  class_methods do
    def has_attachment(attribute)
      belongs_to "#{attribute}_attachment".to_sym, class_name: 'Attachment', foreign_key: "#{attribute}_id", optional: true

      scope "preload_#{attribute}".to_sym, -> { includes("#{attribute}_attachment".to_sym) }

      instance_methods = Module.new do
        define_method attribute do
          attachment = send("#{attribute}_attachment")
          attachment.file if attachment.present?
        end

        define_method "#{attribute}=" do |value|
          if Dragonfly::Model::Attachment === value || Dragonfly::Job === value
            attachment = Attachment.from_data(value.data)
            send("#{attribute}_attachment=", attachment)
          elsif String === value || value.respond_to?(:read)
            attachment = Attachment.from_data(value)
            send("#{attribute}_attachment=", attachment)
          else
            send("#{attribute}_attachment=", value)
          end
        end

        define_method "#{attribute}_stored?" do
          attachment = send("#{attribute}_attachment")
          attachment.present? && attachment.file_stored?
        end
      end

      include instance_methods
    end
  end
end
