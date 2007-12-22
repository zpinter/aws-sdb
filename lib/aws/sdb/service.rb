require 'time'
require 'cgi'
require 'uri'
require 'net/http'

require 'base64'
require 'openssl'

require 'rexml/document'
require 'rexml/xpath'

module AWS
  module SDB
    
    class Service
      def initialize(config = {})
        @aws_access_key_id = 
          config[:access_key_id] || ENV['AMAZON_ACCESS_KEY_ID']
        raise ArgumentError.new('aws access key id') if @aws_access_key_id.nil?
        @aws_secret_access_key = 
          config[:secret_access_key] || ENV['AMAZON_SECRET_ACCESS_KEY']
        raise ArgumentError.new('aws secret key') if @aws_secret_access_key.nil?
      end
    
      # TODO Make this options hash not a param list
      def list_domains(max_results = nil, more_token = nil)
        params = { 'Action' => 'ListDomains' }
        params['MoreToken'] = 
          more_token unless more_token.nil? || more_token.empty?
        params['MaxResults'] = 
          max_results.to_s unless max_results.nil? || max_results.to_i != 0
        doc = call(:get, params)
        domains = []
        REXML::XPath.each(doc, '//DomainName/text()') do |domain| 
          domains << domain.to_s
        end
        { 
          :domains => domains, 
          :more_token => REXML::XPath.each(doc, '/MoreToken/text()').to_s 
        }
      end     
        
      def create_domain(domain_name)
        call(:post, {'Action'=> 'CreateDomain','DomainName'=> domain_name.to_s })
        nil
      end
  
      def delete_domain(domain_name)
        call(:delete, {'Action'=>'DeleteDomain','DomainName'=> domain_name.to_s })
        nil
      end  
    
      def query( 
          domain_name, 
          query_expression, 
          sort = nil,
          max_results = nil, 
          more_token = nil 
        )
        params = { 
          'Action' => 'Query', 
          'QueryExpression' => query_expression,
          'DomainName' => domain_name.to_s 
        }
        params['Sort'] = sort unless sort.nil? || sort.empty?
        params['MoreToken'] = 
          more_token unless more_token.nil? || more_token.empty?
        params['MaxResults'] = 
          max_results.to_s unless max_results.nil? || max_results.to_i != 0
        doc = call(:get, params)
        items = []
        REXML::XPath.each(doc, '//ItemName/text()') do |item| 
          items << item.to_s
        end
        { 
          :items => items, 
          :more_token => REXML::XPath.each(doc, '/MoreToken/text()').to_s 
        }
      end
    
      # TODO Item name should be optional - returning the item name
      # TODO Make replacement optional
      def put_attributes(domain_name, item_name, attributes)
        params = { 
          'Action' => 'PutAttributes', 
          'DomainName' => domain_name.to_s,
          'ItemName' => item_name.to_s,
          'Replace' => true 
        }
        count = 0
        attributes.each do |k,v| 
          count += 1
          params["Attribute.#{count}.Name"] = k.to_s
          params["Attribute.#{count}.Value"] = v.to_s
        end
        call(:put, params)
        params[:item_name]
      end
        
      def get_attributes(domain_name, item_name)
        doc = call( 
          :get, 
          { 
            'Action' => 'GetAttributes', 
            'DomainName' => domain_name.to_s,
            'ItemName' => item_name.to_s 
          } 
        )
        attributes = {}
        REXML::XPath.each(doc, "//Attribute") do |attr|
          attributes[REXML::XPath.first(attr, './Name/text()').to_s.to_sym]=
            REXML::XPath.first(attr, './Value/text()').to_s
        end
        attributes
      end

      def delete_attributes(domain_name, item_name)
        call( 
          :delete, 
          { 
            'Action' => 'DeleteAttributes', 
            'DomainName' => domain_name.to_s,
            'ItemName' => item_name.to_s 
          } 
        )
        nil
      end

      protected
    
      def call(method, params)   
        params.merge!( { 
            'Version' => '2007-02-09',
            'SignatureVersion' => '1',
            'AWSAccessKeyId' => @aws_access_key_id,
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
        hmac = OpenSSL::HMAC.digest(digest, @aws_secret_access_key, data)
        signature = Base64.encode64(hmac).strip
        query << "Signature=#{CGI::escape(signature)}"
        query = query.join('&')
        url = "http://sds.amazonaws.com?#{query}"
        uri = URI.parse(url)
        p url
        response = 
          Net::HTTP.new(uri.host, uri.port).send_request(method, url)
        p response.code, response.body
        # TODO we should put the errors in the exceptions
        raise(ConnectionError.new(response)) unless 
          (200..400).include?(response.code.to_i)
        doc = REXML::Document.new(response.body)
        p doc.to_s
        error = doc.get_elements('*/Errors/Error')[0]
        raise(
          Module.class_eval(
            "AWS::SDB::Error::#{error.get_elements('Code')[0].text}"
          ).new(
            error.get_elements('Message')[0].text
            # doc.get_elements('*/RequestID')[0].text
          ) 
        ) unless error.nil?
        doc
      end
    end

  end
end
