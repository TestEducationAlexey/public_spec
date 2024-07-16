class Shop < ApplicationRecord
  has_many :cards, dependent: :destroy
  has_many :users, through: :cards

  scope :by_user, -> (user_ids) { includes(:users).where(users: { id: user_ids }) }

  validates :name, presence: true, uniqueness: true
end
