require 'webrick'
require 'rails_lite'

describe Params do
  before(:all) do
    class UsersController < ControllerBase
      def index
      end
    end
  end

  let(:req) { WEBrick::HTTPRequest.new(:Logger => nil) }
  let(:res) { WEBrick::HTTPResponse.new(:HTTPVersion => '1.0') }
  let(:users_controller) { UsersController.new(req, res) }

  context "#query_string" do
    it "handles single key and value" do
      req.query_string = "key=val"
      params = Params.new(req)
      params["key"].should == "val"
    end

    it "handles multiple keys and values" do
      req.query_string = "key=val&key2=val2"
      params = Params.new(req)
      params["key"].should == "val"
      params["key2"].should == "val2"
    end

    it "handles nested keys" do
      req.query_string = "user[address][street]=main"
      params = Params.new(req)
      params["user"]["address"]["street"].should == "main"
    end
  end

  context "post body" do
    it "handles single key and value" do
      req.stub(:body) { "key=val" }
      params = Params.new(req)
      params["key"].should == "val"
    end

    it "handles multiple keys and values" do
      req.stub(:body) { "key=val&key2=val2" }
      params = Params.new(req)
      params["key"].should == "val"
      params["key2"].should == "val2"
    end

    it "handles nested keys" do
      req.stub(:body) { "user[address][street]=main" }
      params = Params.new(req)
      params["user"]["address"]["street"].should == "main"
    end
  end
end
