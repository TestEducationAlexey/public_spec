require 'rails_helper'

RSpec.describe "shops#create", type: :request do
  let(:shop) { create_shop }
  let(:user) { create_user }
  let(:use_bonuses) { false }
  let(:amount) { 1 }

  subject(:make_request) do
    buy(shop_id: shop[:id], user_id: user[:id], amount: amount, use_bonuses: use_bonuses)
  end

  it("return ok status") do
    make_request

    expect(response).to have_http_status(:ok)
  end

  it("is success") do
    make_request

    expect(json_body).to include(success: true)
  end

  it "doesn't add bonuses to card" do
    make_request

    expect(json_body).to include(data: hash_including(remaining_bonus: 0))
  end

  it "returns the amount due unchanged" do
    make_request

    expect(json_body).to include(data: hash_including(amount_due: 1))
  end

  context "when check amount less or equal than 0" do
    let(:amount) { 0 }

    before { make_request }

    it("return unprocessable_entity status") { expect(response).to have_http_status(:unprocessable_entity) }
    it("doesn't success") { expect(json_body).to include(success: false) }
    it("returns error") { expect(json_body).to include(errors: hash_including(amount: ["must be greater than 0"])) }
  end

  context "when user_id is blank" do
    before { buy(shop_id: shop[:id], user_id: nil, amount: amount, use_bonuses: use_bonuses) }

    it("return unprocessable_entity status") { expect(response).to have_http_status(:unprocessable_entity) }
    it("doesn't success") { expect(json_body).to include(success: false) }
    it("returns error") { expect(json_body).to include(errors: hash_including(user_id: ["is required"])) }
  end

  context "when amount is blank" do
    before { buy(shop_id: shop[:id], user_id: user[:id], amount: nil, use_bonuses: use_bonuses) }

    it("return unprocessable_entity status") { expect(response).to have_http_status(:unprocessable_entity) }
    it("doesn't success") { expect(json_body).to include(success: false) }
    it("returns error") { expect(json_body).to include(errors: hash_including(amount: ["is required"])) }
  end
end
