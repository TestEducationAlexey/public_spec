class ShopSerializer < ActiveModel::Serializer
  attributes :name

  has_many :cards do
    include_data false

    link(:related) { "/api/v1/cards?filter[shop_id]=#{object.id}" }
  end

  has_many :users, through: :cards do
    include_data false

    link(:related) { "/api/v1/users?filter[shop_id]=#{object.id}" }
  end
end
