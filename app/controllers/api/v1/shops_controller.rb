module API
  module V1
    class ShopsController < ApplicationController
      before_action :validate_buy_params, only: :buy

      def index
        user_id = params.dig(:filter, :user_id)

        @shops = user_id ? Shop.by_user(user_id) : Shop.all

        render json: @shops
      end

      def show
        @shop = Shop.find(params[:id])

        render json: @shop
      rescue StandardError
        render json: NOT_FOUND_ERROR
      end

      def create
        @shop = Shop.new(shop_attributes)

        if @shop.save
          render json: @shop, status: :created
        else
          respond_with_errors(@shop)
        end
      end

      def update
        @shop = Shop.find(params[:id])

        if @shop.update(shop_attributes)
          render json: @shop
        else
          respond_with_errors(@shop)
        end
      end

      def buy
        @shop = Shop.find(params[:id])
        
        render json: BuyService.new(@shop, params).buy! 
      end

      private

      def shop_params
        params.require(:data).permit(:type, { attributes: %i[name] })
      end

      def shop_attributes
        shop_params[:attributes] || {}
      end

      def validate_buy_params
        validator = BuyParamsValidator.new(params)

        return if validator.valid?

        render json: { success: false, errors: validator.errors }, status: :unprocessable_entity
      end
    end
  end
end
