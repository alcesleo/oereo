class Api::V1::ResourcesController < Api::ApiController

  # set pagination headers
  after_filter only: [:index] { paginate(:resources) }

  before_filter :unauthorized_unless_owner!, only: [:update, :destroy]

  def index

    # TODO: This is lazy in Rails 4 right.. right?
    @resources = Resource.all
    # TODO: this smells, refactor into filter_by tags
    if params[:tagged]
      # TODO: support multiple tags
      @resources = Tag.find_by_tag_name(params[:tagged]).resources
    else
      @resources = Resource.all
    end
    filter_by_tags
    filter_by_license
    filter_by_search

    @resources = @resources.page(params[:page]).per(params[:per_page])
    respond_with @resources, meta: pagination_meta
  end

  def show
    respond_with Resource.find(params[:id])
  end

  def create
    @resource = Resource.create(resource_params)
    apply_tags # TODO: optimize, don't save until tags are in?s

    # FIXME: Should :api really be needed? This took way to long to figure out
    respond_with :api, @resource
  end

  def update
    @resource = Resource.update(params[:id], resource_params)
    @resource.tags.clear # TODO: Updating tags can be done more efficiently
    apply_tags
    respond_with :api, @resource
  end

  def destroy
    respond_with Resource.destroy(params[:id])
  end

private

  def filter_by_tags
    # TODO: Implement this
  end

  def filter_by_search
    # ILIKE is a case insensitive search,
    # the param is wrapped in % to indicate it can be placed anywhere in the string
    @resources.where!("title ILIKE ?", "%#{params[:search]}%")
  end

  def filter_by_license
    @resources.where!(license_id: params[:license]) unless params[:license].nil?
  end

  def pagination_meta
    # TODO: Maybe just send the navigation links here as well, the header is hard to work with
    {
      total: @resources.total_count,
      page: @resources.current_page,
      count: @resources.count,
      num_pages: @resources.num_pages,
    }
  end

  def unauthorized_unless_owner!
    head :forbidden unless Resource.find(params[:id]).user == @user
  end

  def apply_tags
    if params[:tags].respond_to?('each')
      params[:tags].each do |tag_name|
        @resource.tags << get_tag(tag_name)
      end
    end
  end

  def get_tag(tag_name)
    tag_name.downcase! # FIXME: case insensitive search for tags?
    Tag.where(tag_name: tag_name).first_or_create
  end

  def resource_params
    {
      title: params[:title],
      description: params[:description],
      url: params[:url],
      user: @user, # set in api_controller
      license: License.find_by(id: params[:license_id]),
      resource_category: ResourceCategory.find_by(id: params[:resource_category_id])
    }
  end

end
