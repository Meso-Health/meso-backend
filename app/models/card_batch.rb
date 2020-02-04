class CardBatch < ApplicationRecord
  has_many :cards, dependent: :destroy

  validates :prefix, format: {with: CardIdGenerator::PREFIX_REGEX}, length: { is: 3 }
  validates :reason, presence: true

  def generate_ids(count)
    count.times do
      cards.create(id: CardIdGenerator.unique(prefix))
    end
    self.cards.reload
  end

  def count
    self.cards.count
  end
end
