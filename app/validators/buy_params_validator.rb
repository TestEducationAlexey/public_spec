class BuyParamsValidator
  include ActiveModel::Validations

  validates_presence_of :amount, message: 'is required'
  validates :amount, numericality: { greater_than: 0 }, allow_nil: true
  validates_inclusion_of :use_bonuses, in: [ true, false ], message: 'must be boolean'
  validates_numericality_of :user_id, greater_than: 0, message: 'is required'

  def initialize(params)
    @params = params
  end

  def read_attribute_for_validation(key)
    return @params[key].to_i if key == 'user_id'

    @params[key]
  end
end
