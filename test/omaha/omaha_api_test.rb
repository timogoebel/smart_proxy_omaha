require 'test_helper'
require 'smart_proxy_omaha/configuration_loader'
require 'smart_proxy_omaha/omaha_plugin'

ENV['RACK_ENV'] = 'test'

class TestForemanClient
  def post_facts(factsdata); end
  def post_report(report); end
end

class TestReleaseRepository
  def releases(track, architecture)
    ['1068.9.0', '1122.2.0'].map { |release| Gem::Version.new(release) }
  end

  def latest_os(track, architecture)
    releases(track, architecture).max
  end
end

class TestMetadataProvider
  def get(track, release, architecture)
    Proxy::Omaha::Metadata.new(
      :track => track,
      :architecture => architecture,
      :release => release,
      :sha1_b64 => '+ZFmPWzv1OdfmKHaGSojbK5Xj3k=',
      :sha256_b64 => 'cSBzKN0c6vKinrH0SdqUZSHlQtCa90vmeKC7p/xk19M=',
      :size => '212555113'
    )
  end

  def store(metadata); end
end

module Proxy::Omaha
  module DependencyInjection
    include Proxy::DependencyInjection::Accessors
    def container_instance
      Proxy::DependencyInjection::Container.new do |c|
        c.singleton_dependency :foreman_client_impl, TestForemanClient
        c.singleton_dependency :release_repository_impl, TestReleaseRepository
        c.singleton_dependency :metadata_provider_impl, TestMetadataProvider
      end
    end
  end
end

require 'smart_proxy_omaha/omaha_api'

class OmahaApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Proxy::Omaha::Api.new
  end

  def test_processes_update_complete_noupdate
    post "/v1/update", xml_fixture('request_update_complete_noupdate')
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
    assert_xml_equal xml_fixture('response_update_complete_noupdate'), last_response.body
  end

  def test_processes_update_complete_update
    post "/v1/update", xml_fixture('request_update_complete_update')
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
    assert_xml_equal xml_fixture('response_update_complete_update'), last_response.body
  end

  def test_processes_update_complete_error
    post "/v1/update", xml_fixture('request_update_complete_error')
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
    assert_xml_equal xml_fixture('response_update_complete_error'), last_response.body
  end
end
