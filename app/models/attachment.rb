class Attachment < ApplicationRecord
  dragonfly_accessor :file

  validates :id, presence: true
  validates :file, presence: true

  before_save :ensure_does_not_exist

  class << self
    def from_data(data)
      data = data.read if data.respond_to?(:read)
      digest = self.digest(data)

      find_by(id: digest) || new(id: digest, file: data)
    end

    def from_dragonfly_uid(uid)
      data = Dragonfly.app.fetch(uid).data
      digest = self.digest(data)

      find_by(id: digest) || new(id: digest, file_uid: uid).tap do |attachment|
        attachment.file.send :set_magic_attributes
      end
    end

    def digest(data)
      Digest::MD5.hexdigest(data)
    end
  end

  private
  def ensure_does_not_exist
    reload if self.class.exists?(id)
  end
end
