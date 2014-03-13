class ResourceSerializer < ActiveModel::Serializer
  attributes :id, :title, :url, :description, :tags, :links

  embed :ids, include: true

  has_one :resource_category
  has_one :license

  def tags
    @object.tags.pluck(:tag_name)
  end

  def links
    # FIXME: Bug in the fork of AMS prevents access to url-methods
    [
      {rel:"self", href: "/api/resources/#{@object.id}" },
      {rel:"resources", href: "/api/resources/" }
    ]
  end

end
