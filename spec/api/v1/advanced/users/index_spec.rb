require 'rails_helper'

RSpec.describe "users#index", type: :request do
  let!(:users) { Array.new(2) { create_user } }

  subject(:make_request) do
    fetch "/api/v1/users"
  end

  it 'return correct jsonapi response' do
    make_request

    aggregate_failures "testing response" do
      expect(response).to have_http_status(:ok)
      expect(json_body[:data]).to have_exactly(2).items
      users.each_with_index do |user, i|
        expect(json_body[:data][i]).to have_id(user[:id])
        expect(json_body[:data][i]).to have_type(:users)
        expect(json_body[:data][i]).to have_jsonapi_attributes(:email, :negative_balance).exactly
        expect(json_body[:data][i]).to have_attribute(:email).with_value(user[:email])
        expect(json_body[:data][i]).to have_relationships(:cards, :shops).exactly
        expect(json_body[:data][i][:relationships][:cards]).to have_link(:related).with_value("/api/v1/cards?filter[user_id]=#{i+1}")
        expect(json_body[:data][i][:relationships][:shops]).to have_link(:related).with_value("/api/v1/shops?filter[user_id]=#{i+1}")
      end
      expect(json_body).to have_meta
    end
  end
end
