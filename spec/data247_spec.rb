require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Data247" do
  before(:all) do
    Data247.username = "username"
    Data247.password = "password"
    Data247.setup_fakeweb_response(:msisdn=>"31612345678", :status=>"OK", :result => 12345)
    Data247.setup_fakeweb_response(:msisdn=>"31612345621", :status => "ERROR")
  end

  describe "detect" do
    it "should return a new Data247 instance" do
      @data247 = Data247.detect(31612345678)
      @data247.should be_instance_of(Data247)
    end

    it "should retry after a timeout and return nil when it still fails" do
      3.times {Timeout.should_receive(:timeout).with(2).and_raise(Timeout::Error)}
      @data247 = Data247.detect(31612345678)
      @data247.should == Data247.new(:status=>"Timeout from Data24-7")
    end

    describe "the returned Data247 instance" do
      let(:data247) { Data247.detect("31612345678") }

      it "should contain the returned operator code" do
        data247.operator_code.should == "12345"
      end

      it "should contain the returned msisdn" do
        data247.msisdn.should == "31612345678"
      end

      it "should contain the operator name" do
        Data247.setup_fakeweb_response(:msisdn=>"31612345679", :status=>"OK", :result => 130730, :operator=>"KPN")
        data = Data247.detect("31612345679")
        data.operator_name.should == "KPN"
      end
    end

    it "should return an instance with error code when no operator code is returned" do
      @data247 = Data247.detect(31612345621)
      @data247.operator_code.should be_nil
      @data247.status.should == "ERROR"
    end
  end
end
