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
