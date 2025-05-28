require 'concurrent'

module ResourceHelper
  def create_user(email: Faker::Internet.unique.email, negative_balance: nil )
    RSPEC_LOGGER.info("Create user".blue)
    create("/api/v1/users", payload:
      generate_payload('users', attributes: { email: email, negative_balance: negative_balance }.compact))
  end

  def create_shop(name: Faker::Company.unique.name)
    RSPEC_LOGGER.info("Create shop".blue)
    create("/api/v1/shops", payload: generate_payload('shops', attributes: { name: name }))
  end

  def buy(amount: 1, use_bonuses: false, user_id:, shop_id:, counter: nil)
    path = "/api/v1/shops/#{shop_id}/buy"
    payload = { amount: amount, use_bonuses: use_bonuses, user_id: user_id }
    log_request(path, "PUT", payload)
    post path, params: payload, as: :json
    log_response(counter)
  end

  def fetch(path)
    log_request(path, "GET")
    jsonapi_get(path)
    log_response
  end

  def update(path, payload)
    log_request(path, "PUT", payload)
    jsonapi_put(path, payload)
    log_response
  end

  def create(path, payload:)
    message = "Request POST - #{path}\n".magenta
    message << payload.ai
    RSPEC_LOGGER.debug(message)
    jsonapi_post path, payload
    log_response
    data = json_body[:data]

    return { id: data[:id], **data[:attributes], relationships: data[:relationships] } if data

    json_body
  end

  def async_request(payloads, memo, method)
    latch = Concurrent::CountDownLatch.new(payloads.size)
    threads = []
    payloads.each_with_index do |payload, i|
      threads << Thread.new(payload, i) do |pld, counter|
        pld[:counter] = counter+1
        RSPEC_LOGGER.info("#{pld[:counter].ordinalize} operation".blue)
        public_send(method, **pld)
        memo << json_body
        latch.count_down
      end
      sleep 0.1
    end
    threads.each(&:join)
    latch.wait
    memo
  end

  private

  def generate_payload(type, attributes:)
    {
      data: {
        type: type,
        attributes: attributes
      }
    }
  end

  def log_request(path, method, payload = nil)
    message = "Request #{method} - #{path}\n".magenta
    message << payload.ai if payload
    RSPEC_LOGGER.debug(message)
  end

  def log_response(counter = nil)
    log_status(counter)
    log_body(counter)
  end

  def log_status(counter = nil)
    message = if counter
                "Response status for #{counter.ordinalize} operation:\n"
              else
                "Response status:\n"
              end.magenta

    message << response.status.ai

    RSPEC_LOGGER.debug(message)
  end

  def log_body(counter = nil)
    message = if counter
                "Response body for #{counter.ordinalize} operation:\n"
              else
                "Response body:\n"
              end.magenta

    message << json_body.ai
    RSPEC_LOGGER.debug(message)
  end
end
