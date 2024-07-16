require 'rails_helper'

RSpec.describe "shops#buy", type: :request do
  let(:shop) { create_shop }
  let(:user) { create_user }
  let(:use_bonuses) { false }

  subject(:make_request) do
    buy(shop_id: shop[:id], user_id: user[:id], amount: amount, use_bonuses: use_bonuses)
  end

  context "when `use bonuses` parameter is false" do
    let(:use_bonuses) { false }

    context "and check amount less than 100" do
      let(:amount) { 99.9 }

      before { make_request }

      it("return ok status") { expect(response).to have_http_status(:ok) }
      it("is success") { expect(json_body).to include(success: true) }
      it("doesn't add bonuses to card") { expect(json_body).to include(data: hash_including(remaining_bonus: 0)) }
      it("returns the amount due unchanged") { expect(json_body).to include(data: hash_including(amount_due: 99.9)) }
    end

    context "and check amount more than 100" do
      let(:amount) { 1000.0 }

      before { make_request }

      it("return ok status") { expect(response).to have_http_status(:ok) }
      it("is success") { expect(json_body).to include(success: true) }
      it("add bonuses to card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 10)) }
      it("returns the amount due unchanged") { expect(json_body).to include(data: hash_including(amount_due: 1000.0)) }
    end
  end

  context "when `use bonuses` parameter is true" do
    let(:use_bonuses) { true }

    context "and the user does not have the negative balance option disabled" do
      context "and current bonuses balance is zero" do
        context "and check amount less than 100" do
          let(:amount) { 99.9 }

          before { make_request }

          it("return ok status") { expect(response).to have_http_status(:ok) }
          it("is success") { expect(json_body).to include(success: true) }
          it("doesn't add bonuses to card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 0)) }
          it("returns the amount due unchanged") { expect(json_body).to include(data: hash_including(amount_due: 99.9)) }
        end

        context "and check amount more than 100" do
          let(:amount) { 1000.0 }

          before { make_request }

          it("return ok status") { expect(response).to have_http_status(:ok) }
          it("is success") { expect(json_body).to include(success: true) }
          it("add bonuses to card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 10)) }
          it("returns the amount due unchanged") { expect(json_body).to include(data: hash_including(amount_due: 1000.0)) }
        end
      end

      context "and current bonuses balance is NOT zero" do
        before { buy(shop_id: shop[:id], user_id: user[:id], amount: 1000 * 100) }

        context "and check amount less than bonuses balance" do
          let(:amount) { 99.9 }

          before { make_request }

          it("return ok status") { expect(response).to have_http_status(:ok) }
          it("is success") { expect(json_body).to include(success: true) }
          it("charge off part of the bonuses from the card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 900)) }
          it("returns a zero amount due") { expect(json_body).to include(data: hash_including(amount_due: 0.0)) }
        end

        context "and check amount equal to bonuses balance" do
          let(:amount) { 1000.0 }

          before { make_request }

          it("return ok status") { expect(response).to have_http_status(:ok) }
          it("is success") { expect(json_body).to include(success: true) }
          it("charge off all bonuses from card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 0)) }
          it("returns a zero amount due") { expect(json_body).to include(data: hash_including(amount_due: 0.0)) }
        end

        context "and check amount more than bonuses balance" do
          let(:amount) { 1500.0 }

          before { make_request }

          it("return ok status") { expect(response).to have_http_status(:ok) }
          it("is success") { expect(json_body).to include(success: true) }
          it("change bonuses on card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 5)) }
          it("returns the remaining amount due") { expect(json_body).to include(data: hash_including(amount_due: 500.0)) }
        end
      end
    end

    context "and the user does not have the negative balance option enabled" do
      before { update("/api/v1/users/#{user[:id]}", user_payload) }

      let(:user_payload) do
        {
          data: {
            id: user[:id],
            type: 'users',
            attributes: { negative_balance: true }
          }
        }
      end

      context "and current bonuses balance is zero" do
        context "and user has second card with nonzero bonuses" do
          let(:second_shop) { create_shop }
          before { buy(shop_id: second_shop[:id], user_id: user[:id], amount: 1000 * 100) }

          context "and check amount less than 100" do
            let(:amount) { 99.9 }

            before { make_request }

            it("return ok status") { expect(response).to have_http_status(:ok) }
            it("is success") { expect(json_body).to include(success: true) }
            it("charge off all bonuses from card and make balance negative")  { expect(json_body).to include(data: hash_including(remaining_bonus: -100)) }
            it("returns a zero amount due") { expect(json_body).to include(data: hash_including(amount_due: 0.0)) }
          end

          context "and check amount more than 100" do
            let(:amount) { 1000.0 }

            before { make_request }

            it("return ok status") { expect(response).to have_http_status(:ok) }
            it("is success") { expect(json_body).to include(success: true) }
            it("charge off all bonuses from card and make balance negative")  { expect(json_body).to include(data: hash_including(remaining_bonus: -1000)) }
            it("returns a zero amount due") { expect(json_body).to include(data: hash_including(amount_due: 0.0)) }
          end
        end

        context "and user has NOT second card" do
          context "and check amount less than 100" do
            let(:amount) { 99.9 }

            before { make_request }

            it("return ok status") { expect(response).to have_http_status(:ok) }
            it("is success") { expect(json_body).to include(success: true) }
            it("doesn't add bonuses to card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 0)) }
            it("returns the amount due unchanged") { expect(json_body).to include(data: hash_including(amount_due: 99.9)) }
          end

          context "and check amount more than 100" do
            let(:amount) { 1000.0 }

            before { make_request }

            it("is success") { expect(json_body).to include(success: true) }
            it("return ok status") { expect(response).to have_http_status(:ok) }
            it("add bonuses to card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 10)) }
            it("returns the amount due unchanged") { expect(json_body).to include(data: hash_including(amount_due: 1000.0)) }
          end
        end
      end

      context "and current bonuses balance is NOT zero" do
        before { buy(shop_id: shop[:id], user_id: user[:id], amount: 1000 * 100) }

        context "and user has NOT second card" do
          context "and check amount less than bonuses balance" do
            let(:amount) { 99.9 }

            before { make_request }

            it("return ok status") { expect(response).to have_http_status(:ok) }

            it("is success") { expect(json_body).to include(success: true) }
            it("charge off part of the bonuses from the card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 900)) }
            it("returns a zero amount due") { expect(json_body).to include(data: hash_including(amount_due: 0.0)) }
          end

          context "and check amount equal to bonuses balance" do
            let(:amount) { 1000.0 }

            before { make_request }

            it("return ok status") { expect(response).to have_http_status(:ok) }
            it("is success") { expect(json_body).to include(success: true) }
            it("charge off all bonuses from card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 0)) }
            it("returns a zero amount due") { expect(json_body).to include(data: hash_including(amount_due: 0.0)) }
          end

          context "and check amount more than bonuses balance" do
            let(:amount) { 1500.0 }

            before { make_request }

            it("return ok status") { expect(response).to have_http_status(:ok) }
            it("is success") { expect(json_body).to include(success: true) }
            it("change bonuses on card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 5)) }
            it("returns the remaining amount due") { expect(json_body).to include(data: hash_including(amount_due: 500.0)) }
          end
        end

        context "and user has second card with nonzero bonuses" do
          let(:second_shop) { create_shop }
          before { buy(shop_id: second_shop[:id], user_id: user[:id], amount: 1000 * 100) }

          context "and check amount less than bonuses balance" do
            let(:amount) { 99.9 }

            before { make_request }

            it("return ok status") { expect(response).to have_http_status(:ok) }
            it("is success") { expect(json_body).to include(success: true) }
            it("charge off part of the bonuses from the card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 900)) }
            it("returns a zero amount due") { expect(json_body).to include(data: hash_including(amount_due: 0.0)) }
          end

          context "and check amount equal to bonuses balance" do
            let(:amount) { 1000.0 }

            before { make_request }

            it("return ok status") { expect(response).to have_http_status(:ok) }
            it("is success") { expect(json_body).to include(success: true) }
            it("charge off all bonuses from card")  { expect(json_body).to include(data: hash_including(remaining_bonus: 0)) }
            it("returns a zero amount due") { expect(json_body).to include(data: hash_including(amount_due: 0.0)) }
          end

          context "and check amount more than bonuses balance", :aggregate_failures do
            let(:amount) { 1500.0 }

            before { make_request }

            it("return ok status") { expect(response).to have_http_status(:ok) }
            it("is success") { expect(json_body).to include(success: true) }
            it("change bonuses on card")  { expect(json_body).to include(data: hash_including(remaining_bonus: -500)) }
            it("returns the remaining amount due") { expect(json_body).to include(data: hash_including(amount_due: 0.0)) }
          end

          context "and check amount more than bonuses balance on all user cards" do
            let(:amount) { 2500.0 }

            before { make_request }

            it("return ok status") { expect(response).to have_http_status(:ok) }

            it("is success") { expect(json_body).to include(success: true) }
            it("change bonuses on card")  { expect(json_body).to include(data: hash_including(remaining_bonus: -995)) }
            it("returns the remaining amount due") { expect(json_body).to include(data: hash_including(amount_due: 500.0)) }
          end
        end
      end
    end
  end
end