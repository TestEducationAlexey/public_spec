class CardSerializer < ActiveModel::Serializer
  attributes :bonuses

  belongs_to :user do
    include_data false

    link(:related) { "/api/v1/users/#{object.user_id}" }
  end

  belongs_to :shop do
    include_data false

    link(:related) { "/api/v1/shops/#{object.shop_id}" }
  end
end
