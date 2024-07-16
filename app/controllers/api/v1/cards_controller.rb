module API
  module V1
    class CardsController < ApplicationController
      def index
        user_id = params.dig(:filter, :user_id)
        shop_id = params.dig(:filter, :shop_id)

        @cards =
          if user_id
            Card.by_user(user_id)
          elsif shop_id
            Card.by_shop(shop_id)
          else
            Card.all
          end

        meta = params.dig(:stats, :bonuses) == 'sum' ? { stats: { bonuses: { sum: @cards.sum(&:bonuses) } } } : {} 

        render json: @cards, meta: meta
      end

      def show
        @card = Card.find(params[:id])

        render json: @card
      rescue StandardError
        render json: NOT_FOUND_ERROR
      end
    end
  end
end
