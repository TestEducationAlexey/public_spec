class Card < ApplicationRecord
  belongs_to :user
  belongs_to :shop

  scope :by_user, -> (user_ids) { where(user_id: user_ids) }
  scope :by_shop, -> (shop_ids) { where(shop_id: shop_ids) }
end
