require 'spec_helper'

describe "Resources API" do

  describe "GET /api/resources" do

    # FIXME: it's REALLY slow to do this each time
    before(:each) do
      full_auth
    end

    it "denies access without token" do
      get '/api/resources'
      expect(response.status).to eq 401 # unauthorized
    end

    it "returns a list of resources" do
      create_list(:resource, 10)

      get '/api/resources', {}, @env
      expect(response.status).to be 200

      # TODO: jsonhelper
      expect(response_json['resources'].length).to eq(10)
    end


    describe "pagination" do

      xit "sends link-headers" do
        get '/api/resources', {}, @env
        # not working?
        expect(response.headers['Link']).to_not be_nil
      end

      it "sends 10 by default" do
        create_list(:resource, 15)
        get '/api/resources', {}, @env

        expect(response_json['resources'].length).to eq(10)
      end

      it "allows custom page lengths" do
        create_list(:resource, 15)
        get '/api/resources?per_page=5', {}, @env
        expect(response_json['resources'].length).to eq(5)
      end

      it "allows getting a specific page" do
        create_list(:resource, 8)

        # only 3 in the last page
        get '/api/resources?per_page=5&page=2', {}, @env
        expect(response_json['resources'].length).to eq(3)
      end

      it "sends an empty array if page is after the last" do
        create_list(:resource, 10)

        # pages after that should be empty
        get '/api/resources?per_page=5&page=3', {}, @env
        expect(response_json['resources'].length).to eq(0)
      end

    end
  end

  describe "POST /api/resources" do

    before(:each) do
      # always send json
      content_type_json

      # create the some associations to work with
      create(:license)
      create(:resource_category, category: 'YouTube')
    end

    it "creates a new resource" do
      full_auth

      json = '{
        "title": "Google",
        "url": "http://www.google.com",
        "description": "A search engine",
        "tags": [
          "searching",
          "googling"
        ],
        "resource_category": "YouTube",
        "license_id": 1
      }'

      expect(Resource.count).to eq(0)
      post '/api/resources', json, @env
      expect(response.status).to be(201)
      expect(Resource.count).to eq(1)
    end

    it "denies post request when not authorized as a user" do
      token_auth
      post '/api/resources', { test: 'value' }.to_json, @env
      expect(response.status).to be(401)
    end

    it "does not allow setting a different user id" do

      full_auth
      user = create(:user)

      json = '{
        "title": "Google",
        "url": "http://www.google.com",
        "description": "A search engine",
        "tags": [
          "searching",
          "googling"
        ],
        "resource_category": "YouTube",
        "license_id": 1,
        "user_id": ' + user.id.to_s + '
      }'

      # it creates the resource, but still sets the current user, and not the one
      # the hacker tried to inject
      post '/api/resources', json, @env
      expect(response.status).to be(201)
      expect(Resource.find_by_user_id(user.id)).to be_nil
      expect(Resource.find_by_user_id(@authorized_user.id)).to_not be_nil
    end

    it "changes a resource" do
      full_auth

      # FIXME: cleaner tests
      json = '{
        "title": "Google",
        "url": "http://www.google.com",
        "description": "A search engine",
        "tags": [
          "searching",
          "googling"
        ],
        "resource_category": "YouTube",
        "license_id": 1
      }'

      # post a resource
      post '/api/resources', json, @env
      resource_id = response_json['resource']['id']

      # change the title with PUT
      changed_json = '{
        "title": "Google Search engine",
        "url": "http://www.google.com",
        "description": "A search engine",
        "tags": [
          "searching",
          "googling"
        ],
        "resource_category": "YouTube",
        "license_id": 1
      }'
      put "/api/resources/#{resource_id}", changed_json, @env

      # make sure the title changed
      expect(Resource.find(resource_id).title).to eq("Google Search engine")
    end
  end

  it "allows editing of owned resources"
  it "does not allow editing of other's resources"

  it "sets the current user on posted resources"

  it "deletes resources if permitted"
end
