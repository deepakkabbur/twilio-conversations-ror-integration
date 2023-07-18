# twilio-conversations-ror-integration
Integrate Twilio Conversations with ROR

## [Twilio Conversation](https://www.twilio.com/docs/conversations)
Twilio Conversations is like group messaging. We need to create group, add participants and send message. A meesage sent to all participants of group. 


## Integration
We need integrated following Twilio API's

##### [Conversation API](https://www.twilio.com/docs/conversations/api/conversation-resource)
- Create
- Fetch
- Update
- Send Message


##### [Participant API](https://www.twilio.com/docs/conversations/api/conversation-participant-resource)
- Add Participant
- Remove Participant


#### Implemenatation

#### Twilio::RestClient
Creates and returns twilio rest client

```ruby
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
```

#### Twilio::ClientFactory
Returns requested client instance

```ruby
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
```

Requirment
- Client has Primary(Organization) and Sub accounts(User). Each account has unique credentials for API integration
- Primary is global account for project
- Sub account is specific to user/entity in project
- According to user we need to fetch respective twilio client
- ```@@clients``` used to memorize clients for speed and optimization. Create client only once and reuse it whenever required

Twilio::Api::Conversation
Integrates Twilio conversation API's
```ruby
module Twilio
  module Api
    module Conversation
      @@states = {inactive: 'inactive', active: 'active', closed: 'closed'}

      def create(friendly_name)
        @twilio_conversation = @client.conversations.v1.conversations.create(friendly_name: friendly_name)
      end

      def fetch(sid)
        @twilio_conversation = @client.conversations.v1.conversations(sid).fetch
      end

      def update_state(state)
        @twilio_conversation = @client.conversations.v1
                                   .conversations(@twilio_conversation.sid)
                                   .update(state: state)
      end

      def active
        update_state(@@states[:active])
      end

      def closed
        update_state(@@states[:closed])
      end

      def inactive
        update_state(@@states[:inactive])
      end

      def delete
        @client.conversations.v1.conversations(@twilio_conversation.sid).delete
      end

      def send_message(body, author)
        @client.conversations
            .v1
            .conversations(@twilio_conversation.sid)
            .messages
            .create(body: body, author: author)
      end
    end
  end
end
```
Twilio::Api::Participant
Integrates Twilio participant API's
```ruby
module Twilio
  module Api
    module Participant
      def add_participant(message_binding_address, messaging_binding_proxy_address)
        ##
        # messaging_binding_address: participant mobile number
        # messaging_binding_proxy_address: twilio number
        puts(message_binding_address, messaging_binding_proxy_address)
        @client.conversations.v1
            .conversations(@twilio_conversation.sid)
            .participants.create(
            messaging_binding_address: message_binding_address,
            messaging_binding_proxy_address: messaging_binding_proxy_address)
      end

      def add_whats_app_participant(message_binding_address, messaging_binding_proxy_address)
        puts 'participant',
        add_participant("whatsapp:#{message_binding_address}",
                        "whatsapp:#{messaging_binding_proxy_address}")
      end

      def remove_participant(participant_sid)
        @client.conversations.v1
            .conversations(@twilio_conversation.sid)
            .participants(participant_sid)
            .delete
      end
    end
  end
end
```

Twilio::Conversation
Class which includes Twilio conversation and participants API and initialization methods

```ruby
module Twilio
  class Conversation
    include Twilio::Api::Conversation
    include Twilio::Api::Participant

    attr_accessor :twilio_conversation

    def initialize(client)
      @client = client
    end

    def sid
      @twilio_conversation.sid
    end

    class << self
      def create(client, name)
        conversation = self.new(client)
        conversation.create(name)
        conversation
      end

      def fetch(client, sid)
        conversation = self.new(client)
        conversation.fetch(sid)
        conversation
      end
    end
  end
end
```

Usage:
```ruby
 client = Twilio::ClientFactory.get(account_sid, auth_token)
 conversation = Twilio::Conversation.create(client, 'Ruby Code Sample')
 conversation.add_participant('charles mobile number', 'twilio phone number')
 conversation.send_message('Hi Charles', author='Organization Name')

```

Integration With ROR:

Requirements:
Client need re-usable twilio module which can be easily integrated with other project easiliy.

1. We created core twilio module which is integrates Twilio API's
2. We added services which integrates ROR modules and Twilio Module

```ruby
module Twilio
  class ConversationService
    class << self
      @@mandatory_params = [:twilio_account_sid, :twilio_auth_token, :twilio_phone_number, :twilio_whatsapp_number,
                            :communication_platform, :name, :conversationable, :property_id]
      # #
      # Parameters : {
      #     'twilio_auth_token': String,
      #     'twilio_account_sid': String,
      #     'twilio_phone_number': String,
      #     'twilio_whats_app_number': String,
      #     'communication_platform': String['SMS', 'WHATSAPP'],
      #     'name': String,
      #     'conversationable': Model Object you want associate with,
      #     'property_id': Integer,
      #     'unique_name': String Optional
      # }
      def create(parameters, twilio_api= Twilio::Conversation, twilio_client_factory=Twilio::ClientFactory)
        validate_params(parameters)
        begin
          conversation = TwilioConversation::Conversation.create_with(status: 'active').create!(parameters)
          twilio_conversation = Twilio::Conversation.create(
              twilio_client_factory.create_client(parameters[:twilio_account_sid], parameters[:twilio_auth_token]),
              parameters[:name]
          )
          conversation.update!(conversation_sid: twilio_conversation.sid)
          return conversation
        rescue Twilio::REST::TwilioError => error
          conversation.update!(error: error.message)
          twilio_conversation && twilio_conversation.closed()
          raise error
        end
      end

      def close(conversation_sid, twilio_api= Twilio::Conversation, twilio_client_factory=Twilio::ClientFactory)
        conversation = TwilioConversation::Conversation.find_by_conversation_sid(conversation_sid)
        twilio_conversation = twilio_api.fetch(
            twilio_client_factory.create_client(conversation.twilio_account_sid, conversation.twilio_auth_token),
            conversation.conversation_sid
        )
        twilio_conversation.send_message(TWILIO_CLOSE_MESSAGE, conversation.property.name)
        twilio_conversation.closed()
        conversation.update_closed
      end

      def validate_params(parameters)
        @@mandatory_params.each do |param|
          raise ArgumentError, "Argument #{param.to_sym} missing" unless (parameters.key?(param.to_sym) and parameters[param.to_sym].present?)
        end
      end
    end
  end
end

```

Responsibilities
- Create/Close Conversation using Twilio::Conversation api
- On Success Save conversation details in database
- On failure save error message 