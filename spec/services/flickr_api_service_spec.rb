# spec/services/flickr_api_service_spec.rb
require 'rails_helper'
require 'net/http'

RSpec.describe FlickrAPIService do
  let(:user_id) { '12345678@N00' }
  let(:api_key) { 'fake_api_key' }
  let(:base_uri) { 'https://api.flickr.com/services/rest' }
  let(:default_params) do
    {
      api_key: api_key,
      format: 'json',
      nojsoncallback: '1'
    }
  end

  before do
    allow(ENV).to receive(:fetch).with('PHOTONIA_FLICKR_API_KEY', nil).and_return(api_key)
  end

  describe '#people_get_info' do
    let(:service) { described_class.new }
    let(:response_body) { { 'stat' => 'ok', 'username' => { '_content' => 'test_user' } }.to_json }
    let(:response) { instance_double(Net::HTTPResponse, body: response_body) }

    before do
      allow(Net::HTTP).to receive(:get_response).and_return(response)
    end

    it 'sets the correct query parameters' do
      expect(URI).to receive(:encode_www_form).with(default_params.merge(method: 'flickr.people.getInfo', user_id: user_id)).and_call_original
      service.people_get_info(user_id)
    end

    it 'returns parsed JSON response' do
      result = service.people_get_info(user_id)
      expect(result).to eq(JSON.parse(response_body))
    end
  end

  describe '.people_get_info_hash' do
    let(:is_deleted) { '0' }
    let(:iconserver) { '1234' }
    let(:iconfarm) { '5' }
    let(:username) { 'test_user' }
    let(:realname) { 'Test User' }
    let(:location) { 'Test Location' }
    let(:timezone_label) { 'Test Timezone' }
    let(:timezone_offset) { '+00:00' }
    let(:timezone_id) { 'Test/Timezone' }
    let(:description) { 'Test Description' }
    let(:photosurl) { 'http://photos.url' }
    let(:profileurl) { 'http://profile.url' }
    let(:photos_firstdatetaken) { '2021-01-01' }
    let(:photos_firstdate) { '2021-01-01' }
    let(:photos_count) { '100' }

    let(:response_body) do
      {
        'stat' => 'ok',
        'person' => {
          'is_deleted' => is_deleted,
          'iconserver' => iconserver,
          'iconfarm' => iconfarm,
          'username' => { '_content' => username },
          'realname' => { '_content' => realname },
          'location' => { '_content' => location },
          'timezone' => {
            'label' => timezone_label,
            'offset' => timezone_offset,
            'timezone_id' => timezone_id
          },
          'description' => { '_content' => description },
          'photosurl' => { '_content' => photosurl },
          'profileurl' => { '_content' => profileurl },
          'photos' => {
            'firstdatetaken' => { '_content' => photos_firstdatetaken },
            'firstdate' => { '_content' => photos_firstdate },
            'count' => { '_content' => photos_count }
          }
        }
      }.to_json
    end

    let(:response) { instance_double(Net::HTTPResponse, body: response_body) }

    before do
      allow(Net::HTTP).to receive(:get_response).and_return(response)
    end

    it 'returns a hash with user info' do
      result = described_class.people_get_info_hash(user_id)
      expect(result).to eq(
        is_deleted: is_deleted == '1',
        iconserver:,
        iconfarm:,
        username:,
        realname:,
        location:,
        timezone_label:,
        timezone_offset:,
        timezone_id:,
        description:,
        photosurl:,
        profileurl:,
        photos_firstdatetaken:,
        photos_firstdate:,
        photos_count:
      )
    end

    it 'returns a hash with is_deleted set to true if user is deleted' do
      response_body = { 'stat' => 'fail', 'message' => 'User deleted' }.to_json
      allow(response).to receive(:body).and_return(response_body)
      result = described_class.people_get_info_hash(user_id)
      expect(result).to eq(is_deleted: true)
    end
  end

  describe '#profile_get_profile' do
    let(:service) { described_class.new }
    let(:response_body) do
      {
        'stat' => 'ok',
        'profile' => {
          'profile_description' => {
            '_content' => 'This is my profile description'
          }
        }
      }.to_json
    end
    let(:response) { instance_double(Net::HTTPResponse, body: response_body) }

    before do
      allow(Net::HTTP).to receive(:get_response).and_return(response)
    end

    it 'sets the correct query parameters' do
      expect(URI).to receive(:encode_www_form).with(default_params.merge(method: 'flickr.profile.getProfile', user_id: user_id)).and_call_original
      service.profile_get_profile(user_id)
    end

    it 'returns parsed JSON response' do
      result = service.profile_get_profile(user_id)
      expect(result).to eq(JSON.parse(response_body))
    end
  end

  describe '.profile_get_profile_description' do
    let(:profile_description) { 'This is my profile description with code ABC123' }
    let(:response_body) do
      {
        'stat' => 'ok',
        'profile' => {
          'profile_description' => {
            '_content' => profile_description
          }
        }
      }.to_json
    end
    let(:response) { instance_double(Net::HTTPResponse, body: response_body) }

    before do
      allow(Net::HTTP).to receive(:get_response).and_return(response)
    end

    it 'returns the profile description' do
      result = described_class.profile_get_profile_description(user_id)
      expect(result).to eq({ '_content' => profile_description })
    end

    context 'when the response is not ok' do
      let(:response_body) { { 'stat' => 'fail' }.to_json }

      it 'returns nil' do
        result = described_class.profile_get_profile_description(user_id)
        expect(result).to be_nil
      end
    end
  end
end
