module AWS
  module SDB
      
    class Error < RuntimeError ; end
  
    class RequestError < Error
      attr_accessor :errors
    
      def initialize(errors = {})
        super(errors.values.inspect)
        @errors = errors      
      end
    end

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
