require 'rails_helper'

RSpec.describe "users#show", type: :request do
  let!(:user) { create_user }

  subject(:make_request) do
    fetch "/api/v1/users/#{user[:id]}"
  end

  it 'return correct jsonapi response' do
    make_request

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

  describe "#filter" do
    let(:shop) { create_shop }
    let(:filter_cards) { json_body.dig(:data, :relationships, :cards, :links, :related) }
    let(:filter_shops) { json_body.dig(:data, :relationships, :shops, :links, :related) }

    before do
      buy(shop_id: shop[:id], user_id: user[:id])
      make_request
      filter_cards
      filter_shops
    end

    it 'return cards associated with user' do
      fetch filter_cards

      aggregate_failures "testing response" do
        expect(response).to have_http_status(:ok)
        expect(json_body[:data]).to have_attributes(size: 1)
        expect(json_body[:data].first).to have_id("1")
        expect(json_body[:data].first).to have_type(:cards)
        expect(json_body[:data].first).to have_jsonapi_attributes(:bonuses).exactly
        expect(json_body[:data].first).to have_relationships(:user, :shop).exactly
        expect(json_body[:data].first.dig(:relationships, :user)).to have_link(:related).with_value("/api/v1/users/1")
        expect(json_body[:data].first.dig(:relationships, :shop)).to have_link(:related).with_value("/api/v1/shops/1")
        expect(json_body).to have_meta
      end
    end

    it 'return shops associated with user through cards' do
      fetch filter_shops

      aggregate_failures "testing response" do
        expect(response).to have_http_status(:ok)
        expect(json_body[:data]).to have_attributes(size: 1)
        expect(json_body[:data].first).to have_id(shop[:id])
        expect(json_body[:data].first).to have_type(:shops)
        expect(json_body[:data].first).to have_jsonapi_attributes(:name).exactly
        expect(json_body[:data].first).to have_relationships(:cards, :users).exactly
        expect(json_body[:data].first.dig(:relationships, :cards)).to have_link(:related).with_value("/api/v1/cards?filter[shop_id]=1")
        expect(json_body[:data].first.dig(:relationships, :users)).to have_link(:related).with_value("/api/v1/users?filter[shop_id]=1")
        expect(json_body).to have_meta
      end
    end
  end
end
