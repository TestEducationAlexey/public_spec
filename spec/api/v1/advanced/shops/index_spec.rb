require 'rails_helper'

RSpec.describe "shops#index", type: :request do
  let!(:shops) { Array.new(2) { create_shop } }

  subject(:make_request) do
    fetch "/api/v1/shops"
  end

  it 'return correct jsonapi response' do
    make_request

    aggregate_failures "testing response" do
      expect(response).to have_http_status(:ok)
      expect(json_body[:data]).to have_exactly(2).items
      shops.each_with_index do |shop, i|
        expect(json_body[:data][i]).to have_id(shop[:id])
        expect(json_body[:data][i]).to have_type(:shops)
        expect(json_body[:data][i]).to have_jsonapi_attributes(:name).exactly
        expect(json_body[:data][i]).to have_attribute(:name).with_value(shop[:name])
        expect(json_body[:data][i]).to have_relationships(:cards, :users).exactly
        expect(json_body[:data][i][:relationships][:cards]).to have_link(:related).with_value("/api/v1/cards?filter[shop_id]=#{i+1}")
        expect(json_body[:data][i][:relationships][:users]).to have_link(:related).with_value("/api/v1/users?filter[shop_id]=#{i+1}")
      end
      expect(json_body).to have_meta
    end
  end
end
