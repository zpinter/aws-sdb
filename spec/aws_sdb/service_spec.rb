require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'digest/sha1'
require 'net/http'
require 'rexml/document'

require 'rubygems'
require 'uuidtools'

include AwsSdb

describe Service, "when creating a new domain" do
  before(:all) do
    @logger = AwsSdb.container.logs.get(:rspec)
    @service = AwsSdb.container.service(
      ENV['AMAZON_ACCESS_KEY_ID'],
      ENV['AMAZON_SECRET_ACCESS_KEY']
    )
    @domain = "test-#{UUID.random_create.to_s}"
    #    domains = @service.list_domains[0]
    #    @logger.debug("Domains #{domains.inspect}")
    #    domains.each do |d|
    #      @service.delete_domain(d)
    #    end
  end

  after(:all) do
    #    @service.delete_domain(@domain)
  end

  def stub_success
    resp = mock(Net::HTTPResponse)
    resp.stub!(:code).and_return("200")
    resp.stub!(:body).and_return(
      """
      <CreateDomainResponse>
        <ResponseStatus>
          <StatusCode>Success</StatusCode>
          <RequestID>#{UUID.random_create.to_s}</RequestID>
          <BoxUsage>0.001</BoxUsage>
        </ResponseStatus>
      </CreateDomainResponse>
      """
    )
    http = mock(Net::HTTP)
    http.stub!(:send_request).and_return(resp)
    Net::HTTP.stub!(:new).and_return(http)
  end

  def stub_error(code, type, message)
    resp = mock(Net::HTTPResponse)
    resp.stub!(:code).and_return(code)
    resp.stub!(:body).and_return(
      """
      <Response>
        <Errors>
          <Error>
            <Code>#{type}</Code>
            <Message>#{message}</Message>
          </Error>
        </Errors>
        <RequestID>#{UUID.random_create.to_s}</RequestID>
      </Response>
      """
    )
    http = mock(Net::HTTP)
    http.stub!(:send_request).and_return(resp)
    Net::HTTP.stub!(:new).and_return(http)
  end
  
  it "should not raise an error if a valid new domain name is given" do
    stub_success
    lambda {
      @service.create_domain("test-#{UUID.random_create.to_s}")
    }.should_not raise_error
  end
  
  it "should not raise an error if the domain name already exists" do
    stub_success
    domain = "test-#{UUID.random_create.to_s}"
    lambda {
      @service.create_domain(domain)
      @service.create_domain(domain)
    }.should_not raise_error
  end
  
  it "should raise an error if an a nil or '' domain name is given" do
    stub_error(
      400, :InvalidDomainName, "The domain name '' is not valid."
    )
    lambda { 
      @service.create_domain('') 
    }.should raise_error(InvalidDomainNameError)
    stub_error(
      400, :InvalidDomainName, "The domain name '     ' is not valid."
    )
    lambda { 
      @service.create_domain('     ')
    }.should raise_error(InvalidDomainNameError)
    stub_error(
      400, :InvalidDomainName, "The domain name '' is not valid."
    )
    lambda { 
      @service.create_domain(nil)
    }.should raise_error(InvalidDomainNameError)
  end

  it "should raise an error if the domain name length is < 3 or > 255" do
    stub_error(
      400, :InvalidDomainName, "The domain name 'xx' is not valid."
    )
    lambda { 
      @service.create_domain('xx')
    }.should raise_error(InvalidDomainNameError)
    stub_error(
      400, 
      :InvalidDomainName, 
      "The domain name '#{:x.to_s*256}' is not valid."
    )
    lambda { 
      @service.create_domain('x'*256)
    }.should raise_error(InvalidDomainNameError)
  end

  it "should only accept domain names with a-z, A-Z, 0-9, '_', '-', and '.' " do
    stub_error(
      400, :InvalidDomainName, "The domain name '@$^*()' is not valid."
    )
    lambda { 
      @service.create_domain('@$^&*()')
    }.should raise_error(InvalidDomainNameError)
  end

  it "should only accept a maximum of 100 domain names" do
    # TODO Implement this example
  end

  it "should not have to call amazon to determine domain name correctness" do
    # TODO Implement this example
  end
end

describe Service, "when listing domains" do
  before(:all) do
    @service = AwsSdb.container.service(
      ENV['AMAZON_ACCESS_KEY_ID'],
      ENV['AMAZON_SECRET_ACCESS_KEY']
    )
    @domain = "test-#{UUID.random_create.to_s}"
    #    @service.list_domains[0].each do |d|
    #      @service.delete_domain(d)
    #    end
    #    @service.create_domain(@domain)
  end

  after(:all) do
    #    @service.delete_domain(@domain)
  end

  it "should return a complete list" do
    resp = mock(Net::HTTPResponse)
    resp.stub!(:code).and_return("200")
    resp.stub!(:body).and_return(
      """
      <ListDomainsResponse>
        <ResponseStatus>
          <StatusCode>Success</StatusCode>
          <RequestID>#{UUID.random_create.to_s}</RequestID>
          <BoxUsage/>
        </ResponseStatus>
        <DomainName>#{@domain}</DomainName>
      </ListDomainsResponse>
      """
    )
    http = mock(Net::HTTP)
    http.stub!(:send_request).and_return(resp)
    Net::HTTP.stub!(:new).and_return(http)
    
    result = nil
    lambda { result = @service.list_domains[0] }.should_not raise_error    
    result.should_not be_nil 
    result.should_not be_empty
    result.size.should == 1
    result.should_not be_nil
    result.include?(@domain).should == true
  end
end

describe Service, "when deleting domains" do
  before(:all) do
    @service = AwsSdb.container.service(
      ENV['AMAZON_ACCESS_KEY_ID'],
      ENV['AMAZON_SECRET_ACCESS_KEY']
    )
    @domain = "test-#{UUID.random_create.to_s}"
    #    @service.list_domains[0].each do |d|
    #      @service.delete_domain(d)
    #    end
    #    @service.create_domain(@domain)
  end
  
  after do
    #    @service.delete_domain(@domain)
  end
  
  def stub_success
    resp = mock(Net::HTTPResponse)
    resp.stub!(:code).and_return("200")
    resp.stub!(:body).and_return(
      """
      <DeleteDomainResponse>
        <ResponseStatus>
           <StatusCode>Success</StatusCode>
           <RequestID>#{UUID.random_create.to_s}</RequestID>
           <BoxUsage/>
        </ResponseStatus>
      </DeleteDomainResponse>
      """
    )
    http = mock(Net::HTTP)
    http.stub!(:send_request).and_return(resp)
    Net::HTTP.stub!(:new).and_return(http)
  end

  it "should be able to delete an existing domain" do
    stub_success
    lambda { @service.delete_domain(@domain) }.should_not raise_error
  end
   
  it "should not raise an error trying to delete a non-existing domain" do
    stub_success
    lambda { 
      @service.delete_domain(UUID.random_create.to_s) 
    }.should_not raise_error
  end
end

describe Service, "when managing items" do
  before(:all) do
    @service = AwsSdb.container.service(
      ENV['AMAZON_ACCESS_KEY_ID'],
      ENV['AMAZON_SECRET_ACCESS_KEY']
    )
    @domain = "test-#{UUID.random_create.to_s}"
#    @service.list_domains[0].each do |d|
#      @service.delete_domain(d)
#    end
#    @service.create_domain(@domain)
    @item = "test-#{UUID.random_create.to_s}"
    @attributes = {
      :question => 'What is the answer?',
      :answer => [ true, 'testing123', 4.2, 42, 420 ]
    }
  end
  
  after(:all) do
#    @service.delete_domain(@domain)
  end
  
  def stub_put
    resp = mock(Net::HTTPResponse)
    resp.stub!(:code).and_return("200")
    resp.stub!(:body).and_return(
      """
      <PutAttributesResponse>
        <ResponseStatus><StatusCode>Success</StatusCode>
          <RequestID>#{UUID.random_create.to_s}</RequestID>
          <BoxUsage/>
        </ResponseStatus>
      </PutAttributesResponse>
      """
    )
    http = mock(Net::HTTP)
    http.stub!(:send_request).and_return(resp)
    Net::HTTP.stub!(:new).and_return(http)    
  end
  
  def stub_get
    resp = mock(Net::HTTPResponse)
    resp.stub!(:code).and_return("200")
    resp.stub!(:body).and_return(
      """
      <GetAttributesResponse>
        <ResponseStatus>
          <StatusCode>Success</StatusCode>
          <RequestID>#{UUID.random_create.to_s}</RequestID>
          <BoxUsage/>
        </ResponseStatus>
        <Attribute>
          <Name>question</Name>
          <Value>What is the answer?</Value>
        </Attribute>
        <Attribute>
          <Name>answer</Name>
          <Value>true</Value>
        </Attribute>
        <Attribute>
          <Name>answer</Name>
          <Value>testing123</Value>
        </Attribute>
        <Attribute>
          <Name>answer</Name>
          <Value>4.2</Value>
        </Attribute>
        <Attribute>
          <Name>answer</Name>
          <Value>42</Value>
        </Attribute>
        <Attribute>
          <Name>answer</Name>
          <Value>420</Value>
        </Attribute>
      </GetAttributesResponse>
      """
    )
    http = mock(Net::HTTP)
    http.stub!(:send_request).and_return(resp)
    Net::HTTP.stub!(:new).and_return(http)    
  end
  
  def stub_query
    resp = mock(Net::HTTPResponse)
    resp.stub!(:code).and_return("200")
    resp.stub!(:body).and_return(
      """
      <QueryResponse>
        <ResponseStatus>
          <StatusCode>Success</StatusCode>
          <RequestID>#{UUID.random_create.to_s}</RequestID>
          <BoxUsage/>
        </ResponseStatus>
        <ItemName>#{@item}</ItemName>
      </QueryResponse>
      """
    )
    http = mock(Net::HTTP)
    http.stub!(:send_request).and_return(resp)
    Net::HTTP.stub!(:new).and_return(http)
  end
  
  def stub_delete
    resp = mock(Net::HTTPResponse)
    resp.stub!(:code).and_return("200")
    resp.stub!(:body).and_return(
      """
      <DeleteAttributesResponse>
        <ResponseStatus>
          <StatusCode>Success</StatusCode>
          <RequestID>#{UUID.random_create.to_s}</RequestID>
          <BoxUsage/>
        </ResponseStatus>
      </DeleteAttributesResponse>
      """
    )
    http = mock(Net::HTTP)
    http.stub!(:send_request).and_return(resp)
    Net::HTTP.stub!(:new).and_return(http)
  end
  
  it "should be able to put attributes" do
    stub_put
    lambda {
      @service.put_attributes(@domain, @item, @attributes)
    }.should_not raise_error
  end

  it "should be able to get attributes" do 
    stub_get
    result = nil
    lambda {
      result = @service.get_attributes(@domain, @item)
    }.should_not raise_error
    result.should_not be_nil
    result.should_not be_empty
    result.has_key?('answer').should == true
    @attributes[:answer].each do |v|
      result['answer'].include?(v.to_s).should == true
    end
  end

  it "should be able to query" do
    stub_query
    result = nil
    lambda {
      result = @service.query(@domain, "[ 'answer' = '42' ]")[0]
    }.should_not raise_error
    result.should_not be_nil
    result.should_not be_empty
    result.should_not be_nil
    result.include?(@item).should == true
  end

  it "should be able to delete attributes" do
    stub_delete
    lambda {
      @service.delete_attributes(@domain, @item)
    }.should_not raise_error
  end
end
