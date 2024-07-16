class UserSerializer < ActiveModel::Serializer
  attributes :email, :negative_balance

  has_many :cards do
    include_data false

    link(:related) { "/api/v1/cards?filter[user_id]=#{object.id}" }
  end

  has_many :shops, through: :cards do
    include_data false

    link(:related) { "/api/v1/shops?filter[user_id]=#{object.id}" }
  end
end
