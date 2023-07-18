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
