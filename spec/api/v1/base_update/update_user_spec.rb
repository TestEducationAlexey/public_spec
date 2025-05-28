require 'rails_helper'

RSpec.describe "users#update", type: :request do
  let!(:user) { create_user }

  subject(:make_request) do
    update("/api/v1/users/#{user[:id]}", payload)
  end

  let(:new_email) { Faker::Internet.unique.email }

  let(:payload) do
    {
      data: {
        id: user[:id],
        type: 'users',
        attributes: {
          email: new_email,
          negative_balance: true
        }
      }
    }
  end

  it 'updates the user' do
    make_request

    expect(response).to have_http_status(:ok)
    expect(json_body[:data]).to have_id(user[:id])
    expect(json_body[:data]).to have_type(:users)
    expect(json_body[:data]).to have_jsonapi_attributes(:email, :negative_balance).exactly
    expect(json_body[:data]).to have_attribute(:email).with_value(new_email)
    expect(json_body[:data]).to have_attribute(:negative_balance).with_value(true)
    expect(json_body[:data]).to have_relationships(:cards, :shops).exactly
    expect(json_body.dig(:data, :relationships, :cards)).to have_link(:related).with_value("/api/v1/cards?filter[user_id]=1")
    expect(json_body.dig(:data, :relationships, :shops)).to have_link(:related).with_value("/api/v1/shops?filter[user_id]=1")
    expect(json_body).to have_meta
  end

  context "when new email is blank" do
    let(:new_email) { "" }
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

  context "when new email is not unique" do
    before { create_user(email: new_email) }

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

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body[:errors].first).to include(expected_error)
    end
  end
end
