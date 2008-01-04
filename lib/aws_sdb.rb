# require needle
require 'rubygems'
require 'needle'

# require modules
require 'aws_sdb/error'
require 'aws_sdb/service'

module AwsSdb

  def self.container
    @@container ||= Needle::Registry.new(
      :logs => { :filename => "aws_sdb.log" }
    ).namespace!(:aws_sdb) do
      
      service(:model => :multiton) do | c, p, access, secret |
        Service.new(c.log_for(p), access, secret)
      end
      
    end
  end
  
end
