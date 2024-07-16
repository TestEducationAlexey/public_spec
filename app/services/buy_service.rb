class BuyService
  def initialize(shop, params)
    @shop = shop
    @use_bonuses = params[:use_bonuses]
    @amount = params[:amount]
    @user_id = params[:user_id].to_i
  end

  def buy! 
    ensure_bonus_card.with_lock do
      @use_bonuses ? charge_off_bonuses : add_bonuses
    end

    { success: true, data: data }
  end

  def data
    { amount_due: @amount, remaining_bonus: card.bonuses }
  end

  def charge_off_bonuses
    user.with_lock do
      if user.negative_balance
        user_bonuses_sum = user_cards.sum(&:bonuses)
  
        remaining_bonus_sum = user_bonuses_sum - @amount.ceil
  
        if remaining_bonus_sum >= 0
          remaining_bonus = card.bonuses - @amount.ceil
          @amount -= @amount
        else
          @amount -= user_bonuses_sum
          remaining_bonus = card.bonuses - user_bonuses_sum
        end
      else
        remaining_bonus = card.bonuses - @amount.ceil
  
        if remaining_bonus >= 0
          @amount -= @amount
        else
          @amount -= card.bonuses
          remaining_bonus = 0
        end
      end
  
      card.update(bonuses: remaining_bonus)    
      add_bonuses
    end
  end

  def ensure_bonus_card
    card || Card.create(user: user, shop: @shop, bonuses: 0)
  end

  def add_bonuses
    if @amount >= 100
      card.update(bonuses: card.bonuses += (@amount / 100).floor)
    end
  end

  def user_cards
    @user_cards ||= user.cards
  end

  def user 
    @user ||= User.find(@user_id)
  end

  def card
    @card ||= @shop.cards.find_by(user_id: @user_id)
  end
end
