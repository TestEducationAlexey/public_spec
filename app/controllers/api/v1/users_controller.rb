module API
  module V1
    class UsersController < ApplicationController
      def index
        shop_id = params.dig(:filter, :shop_id)

        @users = shop_id ? User.by_shop(shop_id) : User.all

        render json: @users
      end

      def show
        @user = User.find(params[:id])

        render json: @user
      rescue StandardError
        render json: NOT_FOUND_ERROR
      end

      def create
        @user = User.new(user_attributes)

        if @user.save
          render json: @user, status: :created
        else
          respond_with_errors(@user)
        end
      end

      def update
        @user = User.find(params[:id])

        if @user.update(user_attributes)
          render json: @user
        else
          respond_with_errors(@user)
        end
      end

      private

      def user_params
        params.require(:data).permit(:type, { attributes: %i[email negative_balance] })
      end

      def user_attributes
        user_params[:attributes] || {}
      end
    end
  end
end
