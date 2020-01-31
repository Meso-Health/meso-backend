class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  has_paper_trail

  def save_with_id_collision!(*args)
    count = (count || 0) + 1

    transaction(isolation: :serializable) do
      if new_record? && self.class.exists?(self.id)
        Rollbar.info "Creating a #{self.class} collided on existing ID=#{self.id}", id: self.id, class: self.class.to_s
        reload
      else
        save!(*args)
      end
    end
  rescue ActiveRecord::StatementInvalid => e
    retry if count < 5 && PG::TRSerializationFailure === e.cause
    raise
  end
end
