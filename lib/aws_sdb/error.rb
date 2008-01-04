module AwsSdb

  class Error < RuntimeError ; end
  
  class RequestError < Error
    attr_reader :request_id
    
    def initialize(message, request_id=nil)
      super(message)
      @request_id = request_id
    end
  end
    
  class InvalidDomainNameError < RequestError ; end

  class ConnectionError < Error
    attr_reader :response
      
    def initialize(response)
      super(
        "#{response.code} \
           #{response.message if response.respond_to?(:message)}"
      )
      @response = response
    end
  end
  
end
