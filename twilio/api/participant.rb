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
