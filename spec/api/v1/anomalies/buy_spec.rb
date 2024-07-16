require 'rails_helper'

RSpec.describe "anomalies", type: :request do
  let(:negative_balance) { false }
  let!(:user) { create_user(negative_balance: negative_balance) }
  let!(:filter_cards) { json_body.dig(:data, :relationships, :cards, :links, :related) }
  let!(:shop) { create_shop }
  let(:async_responses) { [] }
  let(:use_bonuses) { false }
  let(:bonuses_on_start) { rand(50..100) }
  let(:bonuses_for_async) { Array.new(2) { rand(100..150) } }
  let(:payloads) do
    bonuses_for_async.map do |amount|
      { shop_id: shop[:id], user_id: user[:id], amount: amount*100, use_bonuses: use_bonuses }
    end
  end

  describe "check `Lost updates` anomaly" do
    before do
      RSPEC_LOGGER.info("Initialize card for user with #{bonuses_on_start} bonuses".blue)
      buy(shop_id: shop[:id], user_id: user[:id], amount: bonuses_on_start * 100, use_bonuses: false)
      RSPEC_LOGGER.info("Do two buys in one moment.".blue)
      async_request(payloads, async_responses, :buy) # async add 10 and 20 bonuses
      RSPEC_LOGGER.info("Get info about card".blue)
      fetch filter_cards # get result
    end

    context "when `use bonuses` parameter is false" do
      let(:use_bonuses) { false }
      let(:expected_bonuses) { (bonuses_for_async << bonuses_on_start).sum }

      it "add bonuses to card" do
        expect(json_body[:data].first).to have_attribute(:bonuses).with_value(expected_bonuses)
        async_responses.each_with_index do |body, i|
          expect(body.dig(:data, :amount_due)).to eq(bonuses_for_async[i]*100)
          expect(body.dig(:data, :remaining_bonus)).to eq(bonuses_on_start + bonuses_for_async[0..i].sum)
        end
      end
    end

    context "when `use bonuses` parameter is true" do
      let(:use_bonuses) { true }

      context "and check amount less than bonuses balance for each buy, and for sum of checks" do
        let(:bonuses_on_start) { rand(3000..4000) }
        let(:bonuses_for_async) { Array.new(2) { rand(5..10) } }
        let(:expected_bonuses) { bonuses_on_start - bonuses_for_async.map { |bonuses| bonuses * 100 }.sum }

        it "charge bonuses from card" do
          expect(json_body[:data].first).to have_attribute(:bonuses).with_value(expected_bonuses)
          async_responses.each_with_index do |body, i|
            expect(body.dig(:data, :amount_due)).to eq(0)
            expect(body.dig(:data, :remaining_bonus)).to eq(bonuses_on_start - bonuses_for_async[0..i].sum*100)
          end
        end
      end
    end
  end

  describe "check `Non-repeatable read` anomaly" do
    subject { json_body[:data].first.dig(:attributes, :bonuses) }

    before do
      RSPEC_LOGGER.info("Initialize card for user with #{bonuses_on_start} bonuses".blue)
      buy(shop_id: shop[:id], user_id: user[:id], amount: bonuses_on_start * 100, use_bonuses: false)
      RSPEC_LOGGER.info("Do two buys in one moment.".blue)
      async_request(payloads, async_responses, :buy)
      RSPEC_LOGGER.info("Get info about card".blue)
      fetch filter_cards
    end

    context "when `use bonuses` parameter is true" do
      let(:use_bonuses) { true }

      context "and check amount for each buy less than bonuses balance on card, but amount of checks more than bonuses balance on card" do
        let(:bonuses_on_start) { rand(2000..2200) }
        let(:bonuses_for_async) { Array.new(2) { rand(12..16) } }

        it "doesn't make the card balance negative" do
          expect(subject).to be >= 0
        end
      end
    end
  end

  describe "check `Inconsistent write` anomaly" do
    subject { json_body.dig(:meta, :stats, :bonuses, :sum) }

    let!(:second_shop) { create_shop }
    let(:bonuses_on_start) { rand(80..100) }
    let(:bonuses_for_async) { Array.new(2) { rand(110..120) } }
    let(:payloads) do
      [
        { shop_id: shop[:id], user_id: user[:id], amount: rand(80..100)*100, use_bonuses: use_bonuses },
        { shop_id: second_shop[:id], user_id: user[:id], amount: rand(80..100)*100, use_bonuses: use_bonuses }
      ]
    end

    before do
      RSPEC_LOGGER.info("Initialize first card for user with #{bonuses_on_start} bonuses".blue)
      buy(shop_id: shop[:id], user_id: user[:id], amount: bonuses_on_start * 100, use_bonuses: false)
      RSPEC_LOGGER.info("Initialize second card for user with #{bonuses_on_start} bonuses".blue)
      buy(shop_id: second_shop[:id], user_id: user[:id], amount: bonuses_on_start * 100, use_bonuses: false)
      RSPEC_LOGGER.info("Do two buys in one moment in two shops.".blue)
      async_request(payloads, async_responses, :buy)
      RSPEC_LOGGER.info("Get info about card".blue)
      fetch filter_cards+"&stats[bonuses]=sum"
    end

    context "when user has enabled negative balance options" do
      let(:negative_balance) { true }

      context "and `use bonuses` parameter is true" do
        let(:use_bonuses) { true }

        context "and check amount for each buy more than bonuses balance on related card, but amount of checks less than sum of bonuses balance on all user cards" do
          let(:bonuses_on_start) { rand(800..1000) }
          let(:bonuses_for_async) { Array.new(2) { rand(110..120) } }

          it "doesn't make the card balance negative" do
            expect(subject).to be >= 0
          end
        end
      end
    end
  end
end
