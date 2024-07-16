class User < ApplicationRecord
  has_many :cards, dependent: :destroy
  has_many :shops, through: :cards

  scope :by_shop, -> (shop_ids) { includes(:shops).where(shops: { id: shop_ids }) }

  validates :email, presence: true, uniqueness: true
end
