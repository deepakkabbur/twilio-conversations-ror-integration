class Twilio::ClientFactory
  ## Client Factory
  # Factory to create or get twilio clients
  class << self
    @@clients = {}

    def get(account_sid, auth_token)
      @@clients[account_sid] || create_client(account_sid, auth_token)
    end

    def create_client(account_sid, auth_token)
      client = Twilio::RestClient.create(account_sid, auth_token)
      @@clients[account_sid] = client
      client
    end

    def global_client
      @@clients[Twilio::Config::GLOBAL_ACCOUNT_SID] || create_client(
          Twilio::Config::GLOBAL_ACCOUNT_SID, Twilio::Config::GLOBAL_AUTH_TOKEN)
    end
  end
end
