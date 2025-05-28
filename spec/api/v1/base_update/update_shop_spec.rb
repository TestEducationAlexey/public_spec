require 'rails_helper'

RSpec.describe "shops#update", type: :request do
  let!(:shop) { create_shop }

  subject(:make_request) do
    update("/api/v1/shops/#{shop[:id]}", payload)
  end

  let(:new_name) { Faker::Company.unique.name }

  let(:payload) do
    {
      data: {
        id: shop[:id],
        type: 'shops',
        attributes: {
          name: new_name
        }
      }
    }
  end

  it 'updates the shop' do
    make_request

    aggregate_failures "testing response" do
      expect(response).to have_http_status(:ok)
      expect(json_body[:data]).to have_id(shop[:id])
      expect(json_body[:data]).to have_type(:shops)
      expect(json_body[:data]).to have_jsonapi_attributes(:name).exactly
      expect(json_body[:data]).to have_attribute(:name).with_value(new_name)
      expect(json_body[:data]).to have_relationships(:cards, :users).exactly
      expect(json_body.dig(:data, :relationships, :cards)).to have_link(:related).with_value("/api/v1/cards?filter[shop_id]=1")
      expect(json_body.dig(:data, :relationships, :users)).to have_link(:related).with_value("/api/v1/users?filter[shop_id]=1")
      expect(json_body).to have_meta
    end
  end

  context "when new name is blank" do
    let(:new_name) { "" }
    let(:expected_error) {
      {
        code: "unprocessable_content",
        status: "422",
        title: "Validation Error",
        detail: "Name can't be blank",
        source: { pointer: "/data/attributes/name" },
        meta: {
          attribute: "name", message: "can't be blank", code: "blank"
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

  context "when new name is not unique" do
    before { create_shop(name: new_name) }

    let(:expected_error) {
      {
        code: "unprocessable_content",
        status: "422",
        title: "Validation Error",
        detail: "Name has already been taken",
        source: { pointer: "/data/attributes/name" },
        meta: {
          attribute: "name", message: "has already been taken", code: "taken"
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
