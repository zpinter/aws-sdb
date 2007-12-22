require File.dirname(__FILE__) + '/../../spec_helper.rb'

require 'digest/sha1'
require 'net/http'
require 'rexml/document'

require 'rubygems'
require 'uuidtools'

include AWS::SDB

describe Service, "when initialized" do
  it "should by default require environment variables " +
    "AMAZON_ACCESS_KEY_ID & AMAZON_SECRET_ACCESS_KEY" do
    ENV.should_receive(:[]).with('AMAZON_ACCESS_KEY_ID').and_return("X")
    ENV.should_receive(:[]).with('AMAZON_SECRET_ACCESS_KEY').and_return("X")
    lambda { Service.new }.should_not raise_error(ArgumentError)
  end

  it "should require config hash param :access_key_id " +
    "if AMAZON_ACCESS_KEY_ID is undefined" do
    ENV.should_receive(:[]).with('AMAZON_ACCESS_KEY_ID').and_return(nil)
    lambda {
      Service.new( { :secret_access_key => "X" } )
    }.should raise_error(ArgumentError)
    lambda {
      Service.new( { :access_key_id => "X", :secret_access_key => "X" } )
    }.should_not raise_error(ArgumentError)
  end

  it "should require config hash param :secret_access_key " +
    "if AMAZON_SECRET_ACCESS_KEY s undefined" do
    ENV.should_receive(:[]).with('AMAZON_SECRET_ACCESS_KEY').and_return(nil)
    lambda {
      Service.new( { :access_key_id => "X" } )
    }.should raise_error(ArgumentError)
    lambda {
      Service.new( { :access_key_id => "X", :secret_access_key => "X" } )
    }.should_not raise_error(ArgumentError)
  end
end

describe Service, "when creating a new domain" do
  before(:all) do
    ENV.stub!(:[]).with('AMAZON_ACCESS_KEY_ID').and_return("X")
    ENV.stub!(:[]).with('AMAZON_SECRET_ACCESS_KEY').and_return("X")

    @service = Service.new
    # @service.list_domains.each do |d|
    #   @service.delete_domain(d)
    # end
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
  
  it "should not raise an stub_error if a valid new domain name is given" do
    stub_success
    lambda {
      @service.create_domain("test-#{UUID.random_create.to_s}")
    }.should_not raise_error
  end
  
  it "should not raise an stub_error if the domain name already exists" do
    stub_success
    domain = "test-#{UUID.random_create.to_s}"
    lambda {
      @service.create_domain(domain)
      @service.create_domain(domain)
    }.should_not raise_error
  end
  
  it "should raise an stub_error if an a nil or '' domain name is given" do
    stub_error(400, :InvalidDomainName, "The domain name '' is not valid.")
    lambda { 
      @service.create_domain('') 
    }.should raise_error(InvalidDomainName)
    stub_error(400, :InvalidDomainName, "The domain name '     ' is not valid.")
    lambda { 
      @service.create_domain('     ')
    }.should raise_error(InvalidDomainName)
    stub_error(400, :InvalidDomainName, "The domain name '' is not valid.")
    lambda { 
      @service.create_domain(nil)
    }.should raise_error(InvalidDomainName)
  end

  it "should raise an stub_error if the domain name length is < 3 or > 255" do
    stub_error(400, :InvalidDomainName, "The domain name 'xx' is not valid.")
    lambda { 
      @service.create_domain('xx')
    }.should raise_error(InvalidDomainName)
    stub_error(400, :InvalidDomainName, "The domain name '#{:x.to_s*256}' is not valid.")
    lambda { 
      @service.create_domain('x'*256)
    }.should raise_error(InvalidDomainName)
  end

  it "should only accept domain names with a-z, A-Z, 0-9, '_', '-', and '.' " do
    stub_error(400, :InvalidDomainName, "The domain name '@$^*()' is not valid.")
    lambda { 
      @service.create_domain('@$^&*()')
    }.should raise_error(InvalidDomainName)
  end

  it "should only accept a maximum of 100 domain names" do
    # FIXME Needs implementing
  end

  it "should not have to call amazon to determine domain name correctness" do
    # FIXME Needs implementing
  end
end

describe Service, "when listing existing domains" do
  before do
    # ENV.stub!(:[]).with('AMAZON_ACCESS_KEY_ID').and_return("X")
    # ENV.stub!(:[]).with('AMAZON_SECRET_ACCESS_KEY').and_return("X")

    @service = Service.new
    @domain = "test-#{UUID.random_create.to_s}"
    @service.create_domain(@domain)
  end

  after do
    @service.delete_domain(@domain)
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
          <DomainName>example1</DomainName>
          <DomainName>example2</DomainName>
          <DomainName>example3</DomainName>
          <DomainName>#{@domain}</DomainName>
      </ListDomainsResponse>
      """
    )
    http = mock(Net::HTTP)
    http.stub!(:send_request).and_return(resp)
    Net::HTTP.stub!(:new).and_return(http)
    
    result = nil
    lambda { result = @service.list_domains }.should_not raise_error    
    result.should_not be_nil 
    result.should_not be_empty
    result.has_key?(:domains).should == true
    result[:domains].should_not be_nil
    result[:domains].include?(@domain).should == true
  end
end


describe Service, "when listing existing domains" do
  before(:all) do
    # ENV.stub!(:[]).with('AMAZON_ACCESS_KEY_ID').and_return("X")
    # ENV.stub!(:[]).with('AMAZON_SECRET_ACCESS_KEY').and_return("X")

    @service = Service.new
    @domain = "test-#{UUID.random_create.to_s}"
    @service.create_domain(@domain)
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
   
  it "should not raise an stub_error trying to delete a non-existing domain" do
    stub_success
    lambda { @service.delete_domain(UUID.random_create.to_s) }.should_not raise_error
  end
end

#describe Service, "when managing items" do
#  before(:all) do
#    @service = Service.new
#    @attributes = {
#      :question => 'What is the answer?',
#      :answer => '42'
#    }
#  end
#
#  it "should be able to put attributes" do
##    resp = mock("Net::HTTPResponse")
##    resp.stub!(:code).and_return("200")
##    resp.stub!(:body).and_return(
##      """
##      <PutAttributesResponse xmlns='http://sdb.amazonaws.com/doc/2007-02-09/'>
##        <ResponseStatus><StatusCode>Success</StatusCode>
##          <RequestID>2932cb6d-4db9-46cc-b28f-829bc9cadb22</RequestID>
##          <BoxUsage/>
##        </ResponseStatus>
##      </PutAttributesResponse>
##      """
##    )
##    http = mock("Net:HTTP")
##    http.stub!(:send_request).and_return(resp)
##    Net::HTTP.stub!(:new).and_return(http)
#
#    lambda {
#      @service.put_attributes("domain", "item", @attributes)
#    }.should_not raise_error
#  end
#
#  it "should be able to get attributes" do	
##    resp = mock("Net::HTTPResponse")
##    resp.stub!(:code).and_return("200")
##    resp.stub!(:body).and_return(
##      """
##      <GetAttributesResponse xmlns='http://sdb.amazonaws.com/doc/2007-02-09/'>
##        <ResponseStatus>
##          <StatusCode>Success</StatusCode>
##          <RequestID>545f172b-dcfb-4e5e-bebd-028f5696182d</RequestID>
##          <BoxUsage/>
##        </ResponseStatus>
##        <Attribute>
##          <Name>question</Name>
##          <Value>What is the answer?</Value>
##        </Attribute>
##        <Attribute>
##          <Name>answer</Name>
##          <Value>42</Value>
##        </Attribute>
##      </GetAttributesResponse>
##      """
##    )
##    http = mock("Net:HTTP")
##    http.stub!(:send_request).and_return(resp)
##    Net::HTTP.stub!(:new).and_return(http)
#
#    result = nil
#    lambda {
#      result = @service.get_attributes("domain", "item")
#    }.should_not raise_error
#    @attributes.each do |k,v|
#      result.has_key?(k).should == true
#      result[k].should == v
#    end
#  end
#
#  it "should be able to query" do
##    resp = mock("Net::HTTPResponse")
##    resp.stub!(:code).and_return("200")
##    resp.stub!(:body).and_return(
##      """
##      <QueryResponse xmlns='http://sdb.amazonaws.com/doc/2007-02-09/'>
##        <ResponseStatus>
##          <StatusCode>Success</StatusCode>
##          <RequestID>f022671f-02a1-4c40-bc35-c71f1b3028f4</RequestID>
##          <BoxUsage/>
##        </ResponseStatus>
##        <ItemName>item</ItemName>
##      </QueryResponse>
##      """
##    )
##    http = mock("Net:HTTP")
##    http.stub!(:send_request).and_return(resp)
##    Net::HTTP.stub!(:new).and_return(http)
#
#    result = nil
#    lambda {
#      result = @service.query("domain", "[ 'answer' = '42' ]")
#    }.should_not raise_error
#    result.should_not be_nil
#    result.should_not be_empty
#    result.has_key?(:items).should == true
#    result[:items].should_not be_nil
#    result[:items].include?("item").should == true
#  end
#
#  it "should be able to delete attributes" do
##    resp = mock("Net::HTTPResponse")
##    resp.stub!(:code).and_return("200")
##    resp.stub!(:body).and_return(
##      """
##      <DeleteAttributesResponse xmlns='http://sdb.amazonaws.com/doc/2007-02-09/'>
##        <ResponseStatus>
##          <StatusCode>Success</StatusCode>
##          <RequestID>c524ccfd-1ce3-45c7-9cf1-808e1c3a11af</RequestID>
##          <BoxUsage/>
##        </ResponseStatus>
##      </DeleteAttributesResponse>
##      """
##    )
##    http = mock("Net:HTTP")
##    http.stub!(:send_request).and_return(resp)
##    Net::HTTP.stub!(:new).and_return(http)
#
#    lambda {
#      @service.delete_attributes("domain", "item")
#    }.should_not raise_error
#  end
#end
