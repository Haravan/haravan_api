require 'rubygems'
require 'test/unit'
require 'fakeweb'
require 'mocha/setup'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'haravan_api'

FakeWeb.allow_net_connect = false

# setup HaravanAPI with fake api_key and secret

class Test::Unit::TestCase
  def self.test(string, &block)
    define_method("test:#{string}", &block)
  end

  def self.should(string, &block)
    self.test("should_#{string}", &block)
  end

  def self.context(string)
    yield
  end

  def setup
    ActiveResource::Base.format = :json
    HaravanAPI.constants.each do |const|
      begin
        const = "HaravanAPI::#{const}".constantize
        const.format = :json if const.respond_to?(:format=)
      rescue NameError
      end
    end

    HaravanAPI::Base.clear_session
    HaravanAPI::Base.site = "https://this-is-my-test-shop.myharavan.com/admin"
    HaravanAPI::Base.password = nil
    HaravanAPI::Base.user = nil
  end

  def teardown
    FakeWeb.clean_registry
  end

  # Custom Assertions
  def assert_not(expression)
    assert_block("Expected <#{expression}> to be false!") { not expression }
  end

  def load_fixture(name, format=:json)
    File.read(File.dirname(__FILE__) + "/fixtures/#{name}.#{format}")
  end

  def fake(endpoint, options={})
    body   = options.has_key?(:body) ? options.delete(:body) : load_fixture(endpoint)
    format = options.delete(:format) || :json
    method = options.delete(:method) || :get
    extension = ".#{options.delete(:extension)||'json'}" unless options[:extension]==false

    url = if options.has_key?(:url)
      options[:url]
    else
      "https://this-is-my-test-shop.myharavan.com/admin/#{endpoint}#{extension}"
    end

    FakeWeb.register_uri(method, url, {:body => body, :status => 200, :content_type => "text/#{format}", :content_length => 1}.merge(options))
  end
end
