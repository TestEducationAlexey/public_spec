require 'rails_helper'

RSpec.describe "cards#index", type: :request do
  let!(:shops) { Array.new(2) { create_shop } }
  let!(:users) { Array.new(2) { create_user } }
  let!(:cards) { [{id: "1", bonuses: 0}, {id: "2", bonuses: 0}] }
  let(:path) { "/api/v1/cards" }

  before do
    shops.each_with_index do |shop, index|
      buy(shop_id: shop[:id], user_id: users[index][:id], amount: cards[index][:bonuses]*100+1)
    end
  end

  subject(:make_request) { fetch path }

  subject { response }

  it 'return correct jsonapi response' do
    make_request

    expect(response).to have_http_status(:ok)
    expect(json_body[:data]).to have_exactly(2).items
    cards.each_with_index do |card, i|
      expect(json_body[:data][i]).to have_id(card[:id])
      expect(json_body[:data][i]).to have_type(:cards)
      expect(json_body[:data][i]).to have_jsonapi_attributes(:bonuses).exactly
      expect(json_body[:data][i]).to have_attribute(:bonuses).with_value(card[:bonuses])
      expect(json_body[:data][i]).to have_relationships(:shop, :user).exactly
      expect(json_body[:data][i][:relationships][:shop]).to have_link(:related).with_value("/api/v1/shops/#{i+1}")
      expect(json_body[:data][i][:relationships][:user]).to have_link(:related).with_value("/api/v1/users/#{i+1}")
    end
    expect(json_body).to have_meta
  end

  context "when we request information about the amount of bonuses on the cards" do
    let(:path) { "/api/v1/cards?stats[bonuses]=sum" }
    let!(:cards) { [{id: "1", bonuses: 5}, {id: "2", bonuses: 10}] }

    it 'return correct jsonapi meta with stats' do
      make_request

      expect(response).to have_http_status(:ok)
      expect(json_body[:data]).to have_exactly(2).items
      cards.each_with_index do |card, i|
        expect(json_body[:data][i]).to have_id(card[:id])
        expect(json_body[:data][i]).to have_type(:cards)
        expect(json_body[:data][i]).to have_jsonapi_attributes(:bonuses).exactly
        expect(json_body[:data][i]).to have_attribute(:bonuses).with_value(card[:bonuses])
        expect(json_body[:data][i]).to have_relationships(:shop, :user).exactly
        expect(json_body[:data][i][:relationships][:shop]).to have_link(:related).with_value("/api/v1/shops/#{i+1}")
        expect(json_body[:data][i][:relationships][:user]).to have_link(:related).with_value("/api/v1/users/#{i+1}")
      end
      expect(json_body).to include(meta: { stats: { bonuses: { sum: 15 } } })
    end
  end
end
