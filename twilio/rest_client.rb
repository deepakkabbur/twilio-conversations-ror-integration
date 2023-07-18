require 'twilio-ruby'

class Twilio::RestClient
  ##
  # Create twilio client class
  # account_sid: Security identifier. Get from Twilio. (aid is of global account or subaccounts)
  # auth_token: The authorization token for this account. This token should be kept a secret, so no sharing.
  # https://www.twilio.com/docs/iam/api/account
  class << self
    def create(account_sid, auth_token)
      Twilio::REST::Client.new account_sid, auth_token
    end
  end
end
