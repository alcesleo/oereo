require 'spec_helper'

describe "Resources API" do
  describe "GET /api/resources" do

    # FIXME: it's REALLY slow to do this each time
    before(:each) do
      token_auth
      user_auth
    end

    it "denies access without token" do
      get '/api/resources'
      expect(response.status).to eq 401 # unauthorized
    end

    it "returns all the resources" do
      create_list(:resource, 10)

      get '/api/resources', {}, @env
      expect(response.status).to be 200

      json = JSON.parse(response.body)
      expect(json['resources'].length).to eq(10)
    end
  end
end
