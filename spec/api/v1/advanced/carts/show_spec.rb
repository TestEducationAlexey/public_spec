require 'rails_helper'

RSpec.describe "cards#show", type: :request do
  let!(:shop) { create_shop }
  let!(:user) { create_user }

  before { buy(shop_id: shop[:id], user_id: user[:id]) }

  subject(:make_request) do
    fetch "/api/v1/cards/1"
  end

  it 'return correct jsonapi response' do
    make_request

    aggregate_failures "testing response" do
      expect(response).to have_http_status(:ok)
      expect(json_body[:data]).to have_id("1")
      expect(json_body[:data]).to have_type(:cards)
      expect(json_body[:data]).to have_jsonapi_attributes(:bonuses).exactly
      expect(json_body[:data]).to have_attribute(:bonuses).with_value(0)
      expect(json_body[:data]).to have_relationships(:user, :shop).exactly
      expect(json_body.dig(:data, :relationships, :user)).to have_link(:related).with_value("/api/v1/users/1")
      expect(json_body.dig(:data, :relationships, :shop)).to have_link(:related).with_value("/api/v1/shops/1")
      expect(json_body).to have_meta
    end
  end

  describe "#filter" do
    let(:user) { create_user }
    let(:filter_shop) { json_body.dig(:data, :relationships, :shop, :links, :related) }
    let(:filter_user) { json_body.dig(:data, :relationships, :user, :links, :related) }

    before do
      buy(shop_id: shop[:id], user_id: user[:id])
      make_request
      filter_shop
      filter_user
    end

    it 'return shop associated with card' do
      fetch filter_shop

      aggregate_failures "testing response" do
        expect(response).to have_http_status(:ok)
        expect(json_body[:data]).to have_id("1")
        expect(json_body[:data]).to have_type(:shops)
        expect(json_body[:data]).to have_jsonapi_attributes(:name).exactly
        expect(json_body[:data]).to have_relationships(:users, :cards).exactly
        expect(json_body.dig(:data, :relationships, :users)).to have_link(:related).with_value("/api/v1/users?filter[shop_id]=1")
        expect(json_body.dig(:data, :relationships, :cards)).to have_link(:related).with_value("/api/v1/cards?filter[shop_id]=1")
        expect(json_body).to have_meta
      end
    end

    it 'return user associated with card' do
      fetch filter_user

      aggregate_failures "testing response" do
        expect(response).to have_http_status(:ok)
        expect(json_body[:data]).to have_id(user[:id])
        expect(json_body[:data]).to have_type(:users)
        expect(json_body[:data]).to have_jsonapi_attributes(:email, :negative_balance).exactly
        expect(json_body[:data]).to have_relationships(:cards, :shops).exactly
        expect(json_body.dig(:data, :relationships, :cards)).to have_link(:related).with_value("/api/v1/cards?filter[user_id]=1")
        expect(json_body.dig(:data, :relationships, :shops)).to have_link(:related).with_value("/api/v1/shops?filter[user_id]=1")
        expect(json_body).to have_meta
      end
    end
  end
end
