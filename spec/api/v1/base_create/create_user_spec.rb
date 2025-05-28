require 'rails_helper'

RSpec.describe "users#create", type: :request do
  let(:email) { Faker::Internet.unique.email }
  let(:negative_balance) { nil }
  subject(:make_request) { create_user(email: email, negative_balance: negative_balance) }

  it 'create shop' do
    make_request

    aggregate_failures "testing response" do
      expect(response).to have_http_status(:created)
      expect(json_body[:data]).to have_id("1")
      expect(json_body[:data]).to have_type(:users)
      expect(json_body[:data]).to have_jsonapi_attributes(:email, :negative_balance).exactly
      expect(json_body[:data]).to have_attribute(:email).with_value(email)
      expect(json_body[:data]).to have_relationships(:cards, :shops).exactly
      expect(json_body.dig(:data, :relationships, :cards)).to have_link(:related).with_value("/api/v1/cards?filter[user_id]=1")
      expect(json_body.dig(:data, :relationships, :shops)).to have_link(:related).with_value("/api/v1/shops?filter[user_id]=1")
      expect(json_body).to have_meta
    end
  end

  context "when email is blank" do
    let(:email) { "" }
    let(:expected_error) {
      {
        code: "unprocessable_content",
        status: "422",
        title: "Validation Error",
        detail: "Email can't be blank",
        source: { pointer: "/data/attributes/email" },
        meta: {
          attribute: "email", message: "can't be blank", code: "blank"
        }
      }
    }

    it 'return jsonapi error' do
      make_request

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body[:errors].first).to include(expected_error)
    end
  end

  context "when email is not unique" do
    before { create_user(email: email) }

    let(:expected_error) {
      {
        code: "unprocessable_content",
        status: "422",
        title: "Validation Error",
        detail: "Email has already been taken",
        source: { pointer: "/data/attributes/email" },
        meta: {
          attribute: "email", message: "has already been taken", code: "taken"
        }
      }
    }

    it 'return jsonapi error' do
      make_request

      aggregate_failures "testing response" do
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_body[:errors].first).to include(expected_error)
      end
    end
  end
end
