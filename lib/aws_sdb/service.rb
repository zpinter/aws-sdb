require 'time'
require 'cgi'
require 'uri'
require 'net/http'

require 'base64'
require 'openssl'

require 'rexml/document'
require 'rexml/xpath'

module AwsSdb
    
  class Service
    def initialize(logger, access_key_id, secret_access_key)
      @logger = logger
      @access_key_id = access_key_id 
      @secret_access_key = secret_access_key
    end
    
    def list_domains(max = nil, token = nil)
      params = { 'Action' => 'ListDomains' }
      params['MoreToken'] = 
        token unless token.nil? || token.empty?
      params['MaxResults'] = 
        max.to_s unless max.nil? || max.to_i == 0
      doc = call(:get, params)
      results = []
      REXML::XPath.each(doc, '//DomainName/text()') do |domain| 
        results << domain.to_s
      end
      return results, REXML::XPath.each(doc, '/MoreToken/text()').to_s 
    end
        
    def create_domain(domain)
      call(:post, { 'Action' => 'CreateDomain', 'DomainName'=> domain.to_s })
      nil
    end
  
    def delete_domain(domain)
      call(
        :delete, 
        { 'Action' => 'DeleteDomain', 'DomainName' => domain.to_s }
      )
      nil
    end  
    
    def query(domain, query, sort = nil, max = nil, token = nil)
      params = { 
        'Action' => 'Query', 
        'QueryExpression' => query,
        'DomainName' => domain.to_s 
      }
      params['Sort'] = sort unless sort.nil? || sort.empty?
      params['MoreToken'] = 
        token unless token.nil? || token.empty?
      params['MaxResults'] = 
        max.to_s unless max.nil? || max.to_i != 0
      doc = call(:get, params)
      results = []
      REXML::XPath.each(doc, '//ItemName/text()') do |item| 
        results << item.to_s
      end
      return results, REXML::XPath.each(doc, '/MoreToken/text()').to_s 
    end
    
    def put_attributes(domain, item, attributes, replace = true)
      params = { 
        'Action' => 'PutAttributes', 
        'DomainName' => domain.to_s,
        'ItemName' => item.to_s
      }
      count = 0
      attributes.each do | key, values | 
        ([]<<values).flatten.each do |value|
          params["Attribute.#{count}.Name"] = key.to_s
          params["Attribute.#{count}.Value"] = value.to_s
          params["Attribute.#{count}.Replace"] = replace
          count += 1
        end
      end
      call(:put, params)
      nil
    end
        
    def get_attributes(domain, item)
      doc = call( 
        :get, 
        { 
          'Action' => 'GetAttributes', 
          'DomainName' => domain.to_s,
          'ItemName' => item.to_s 
        } 
      )
      attributes = {}
      REXML::XPath.each(doc, "//Attribute") do |attr|
        key = REXML::XPath.first(attr, './Name/text()').to_s
        value = REXML::XPath.first(attr, './Value/text()').to_s
        ( attributes[key] ||= [] ) << value
      end
      attributes
    end

    def delete_attributes(domain, item)
      call( 
        :delete, 
        { 
          'Action' => 'DeleteAttributes', 
          'DomainName' => domain.to_s,
          'ItemName' => item.to_s 
        } 
      )
      nil
    end

    protected
    
    def call(method, params)   
      params.merge!( { 
          'Version' => '2007-11-07',
          'SignatureVersion' => '1',
          'AWSAccessKeyId' => @access_key_id,
          'Timestamp' => Time.now.gmtime.iso8601
        } 
      )
      data = ''
      query = []
      params.keys.sort_by { |k| k.upcase }.each do |key|
        data << "#{key}#{params[key].to_s}"
        query << "#{key}=#{CGI::escape(params[key].to_s)}"
      end
      digest = OpenSSL::Digest::Digest.new('sha1')
      hmac = OpenSSL::HMAC.digest(digest, @secret_access_key, data)
      signature = Base64.encode64(hmac).strip
      query << "Signature=#{CGI::escape(signature)}"
      query = query.join('&')
      url = "http://sds.amazonaws.com?#{query}"
      uri = URI.parse(url)
      response = 
        Net::HTTP.new(uri.host, uri.port).send_request(method, url)
      @logger.debug("#{url} #{response.code} #{response.body}")
      raise(ConnectionError.new(response)) unless (200..400).include?(
        response.code.to_i
      )
      doc = REXML::Document.new(response.body)
      error = doc.get_elements('*/Errors/Error')[0]
      raise(
        Module.class_eval(
          "AwsSdb::#{error.get_elements('Code')[0].text}Error"
        ).new(
          error.get_elements('Message')[0].text,
          doc.get_elements('*/RequestID')[0].text
        ) 
      ) unless error.nil?
      doc
    end
  end

end
