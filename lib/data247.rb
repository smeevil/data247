require 'open-uri'
require 'timeout'
require 'active_support'

class Data247
  attr_accessor :operator_name, :operator_code, :msisdn, :status

  def initialize(attributes={})
    attributes.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  class << self
    attr_accessor :username, :password, :timeout, :retries

    def timeout
      @timeout ||= 2
    end

    def retries
      @retries ||= 2
    end

    def password
      @password || raise("No password set for Data24-7")
    end

    def username
      @username || raise("No username set for Data24-7")
    end

    # Attempt an operator lookup based on msisdn.
    def detect(msisdn)
      attempts = 0
      while attempts <= self.retries
        attempts += 1
        begin
          Timeout::timeout(self.timeout) do
            data=Hash.from_xml(open("http://api.data24-7.com/carrier.php?username=#{self.username}&password=#{self.password}&p1=#{msisdn}").read)["response"]["results"]["result"]
            status=data["status"].to_s.strip
            operator_name=data["carrier_name"].to_s.strip
            operator_code=data["carrier_id"].to_s.strip
            unless status != "OK"
              return new(:operator_name=> operator_name, :operator_code => operator_code, :msisdn => msisdn, :status=>status)
            else
              return new(:operator_code => nil, :msisdn => msisdn, :status=>status)
            end
          end
        rescue Timeout::Error, SystemCallError => e
          # ignore
        end
      end
      new(:status=>"Timeout from Data24-7")
    end

    # When using FakeWeb for testing (which you should), use this to setup a fake response that returns the data you want.
    #
    # Required parameters:
    # * :msisdn
    #
    # Optional parameters:
    # * :status (defaults to "OK")
    # * :username (defaults to Data247.username)
    # * :password (defaults to Data247.password)
    # * :operator (defaults to "T-Mobile")
    # * :result (operator code, defaults to "123345", the T-Mobile operator code)
    def setup_fakeweb_response(options={})
      raise "FakeWeb is not defined. Please require 'fakeweb' and make sure the fakeweb rubygem is installed." unless defined?(FakeWeb)
      raise ArgumentError.new("Option missing: :msisdn") unless options[:msisdn]
      options[:status]  ||= "OK"
      options[:username]||= self.username
      options[:password]||= self.password
      options[:operator] ||= "T-Mobile"
      options[:result] ||= "123345"
      FakeWeb.register_uri :get, "http://api.data24-7.com/carrier.php?username=#{options[:username]}&password=#{options[:password]}&p1=#{options[:msisdn]}", :body=> <<-MSG
<?xml version="1.0"?><response><results><result item="1"><status>#{options[:status]}</status><number>#{options[:msisdn]}</number><wless>y</wless><carrier_name>#{options[:operator]}</carrier_name><carrier_id>#{options[:result]}</carrier_id><sms_address>#{options[:msisdn]}@tmomail.net</sms_address><mms_address>#{options[:msisdn]}@tmomail.net</mms_address></result></results><balance>21.5000</balance></response>
MSG
    end
  end

  def ==(other)
    [:operator_code, :msisdn, :status].each do |attribute|
      return false unless self.send(attribute) == other.send(attribute)
    end
    true
  end
end
