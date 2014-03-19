require 'spec_helper'

describe "Resources API" do

  describe "GET /api/resources" do

    # FIXME: it's REALLY slow to do this each time
    before(:each) do
      full_auth
    end

    # TODO: break out into authorization test?
    it "denies access without token" do
      get '/api/resources' # not sending auth headers
      expect(response.status).to eq 401 # unauthorized
    end

    it "returns a list of resources" do
      create_list(:resource, 10)

      get '/api/resources', {}, @env
      expect(response.status).to be 200

      # TODO: jsonhelper
      expect(response_json['resources'].length).to eq(10)
    end

    describe "search and filter" do
      it "filters based on tag" do
        ruby = Tag.create(tag_name: 'ruby')
        python = Tag.create(tag_name: 'python')

        r1 = create(:resource, tags: [ruby, python])
        r2 = create(:resource, tags: [ruby])
        r3 = create(:resource, tags: [python])

        get '/api/resources?tagged=ruby', {}, @env

        # TODO: can I do this without reading the json?
        # make sure it only returns 2 and none of them is r3
        expect(response_json['resources'].length).to eq 2
        expect(response_json['resources'][0]['id']).to_not eq r3.id
        expect(response_json['resources'][1]['id']).to_not eq r3.id
      end

      it "filters based on license" do
        l1 = create(:license)
        l2 = create(:license)

        r1 = create(:resource, license: l1)
        r2 = create(:resource, license: l2)

        get "/api/resources?license=#{l1.id}", {}, @env

        expect(response_json['resources'].length).to eq 1
        expect(response_json['resources'][0]['id']).to eq r1.id
      end

      it "searches for resources by title" do

        r1 = create(:resource, title: "One")
        r2 = create(:resource, title: "Two")

        get "/api/resources?search=one", {}, @env

        expect(response_json['resources'].length).to eq 1
        expect(response_json['resources'][0]['id']).to eq r1.id
      end
    end


    describe "pagination" do

      # FIXME: not working?
      xit "sends link-headers" do
        get '/api/resources', {}, @env
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

      describe "meta" do

        before :each do
          create_list(:resource, 15)
        end

        it "sends correct total" do
          get '/api/resources', {}, @env
          expect(response_json['meta']['total']).to eq 15
        end

        it "sends correct page" do
          get '/api/resources', {}, @env
          expect(response_json['meta']['page']).to eq 1
        end

        it "sends correct count" do
          get '/api/resources', {}, @env
          expect(response_json['meta']['count']).to eq 10
        end

        it "sends correct num_pages" do
          get '/api/resources', {}, @env
          expect(response_json['meta']['num_pages']).to eq 2
        end

        it "sends correct total with option" do
          get 'api/resources?page=2&per_page=5', {}, @env
          expect(response_json['meta']['total']).to eq 15
        end

        it "sends correct page with option" do
          get 'api/resources?page=2&per_page=5', {}, @env
          expect(response_json['meta']['page']).to eq 2
        end

        it "sends correct count with option" do
          get 'api/resources?page=2&per_page=5', {}, @env
          expect(response_json['meta']['count']).to eq 5
        end

        it "sends correct num_pages with option" do
          get 'api/resources?page=2&per_page=5', {}, @env
          expect(response_json['meta']['num_pages']).to eq 3
        end

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

      json = json_for(:resource)

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
      json = json_for(:resource, user: user)

      # it creates the resource, but still sets the current user, and not the one
      # the hacker tried to inject
      post '/api/resources', json, @env
      expect(response.status).to be(201)
      expect(Resource.find_by(user_id: user.id)).to be_nil
      expect(Resource.find_by(user_id: @authorized_user.id)).to_not be_nil
    end

    it "sends unauthorized with malformatted authorization headers" do

      token_auth
      @env['HTTP_AUTHORIZATION'] = 'Basic asdfdGVzdDpwYXNzd29yZA=='

      json = json_for(:resource)

      post "/api/resources", json, @env
      expect(response.status).to be(401)
    end

  end

  describe "PUT /api/resources" do

    before(:each) do
      # always send json
      content_type_json

      # create the some associations to work with
      create(:license)
      create(:resource_category, category: 'YouTube')
    end

    it "changes a resource" do
      full_auth
      resource = create(:resource, user: @authorized_user)

      # change the title with PUT
      json = json_for(:resource, title: 'Google Search engine')
      put "/api/resources/#{resource.id}", json, @env

      # make sure the title changed
      expect(Resource.find(resource.id).title).to eq("Google Search engine")
    end


    it "does not permit changing of other's resources" do
      full_auth

      other_user = create(:user)
      other_resource = create(:resource, user: other_user, title: 'Original')

      json = json_for(:resource, title: 'Changed')
      put "/api/resources/#{other_resource.id}", json, @env

      expect(response.status).to eq 403 # forbidden
      other_resource.reload
      expect(other_resource.title).to eq 'Original'
    end
  end

  describe "DELETE /api/resources" do
    it "allows deletion of own resources" do
      full_auth
      owned_resource = create(:resource, user: @authorized_user)

      delete "/api/resources/#{owned_resource.id}", {}, @env
      expect(response.status).to eq 204 # no content
      expect(Resource.count).to eq 0 # it's gone
    end

    # TODO: implement permissons
    it "does not permit deletion of other's resources" do
      full_auth

      other_user = create(:user)
      other_resource = create(:resource, user: other_user)

      delete "/api/resources/#{other_resource.id}", {}, @env
      expect(response.status).to eq 403 # forbidden
      expect(Resource.count).to eq 1 # it's still there
    end

  end

end
