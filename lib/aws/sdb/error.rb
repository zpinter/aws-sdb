module AWS
  module SDB

    class Error < RuntimeError ; end
  
    class RequestError < Error ; end
    
    class InvalidDomainName < RequestError ; end

    class ConnectionError < Error
      attr_reader :response
      
      def initialize(response)
        super(
          "#{response.code} #{response.message \
             if response.respond_to?(:message)}"
        )
        @response = response
      end
    end
  
  end
end
