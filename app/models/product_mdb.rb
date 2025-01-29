class ProductMdb
  include Mongoid::Document
  include Mongoid::Timestamps

  field :country, type: String
  field :brand, type: String
  field :product_id, type: Integer
  field :product_name, type: String
  field :shop_name, type: String
  field :product_category_id, type: Integer
  field :price, type: Float
  field :url, type: String

  validates :country, :brand, :product_id, :product_name, :shop_name, :product_category_id, :price, :url, presence: true
  validates :product_id, uniqueness: { 
      scope: [:country, :shop_name], 
      message: "must be unique for the same country and shop."
  }

  index({ product_id: 1, country: 1, shop_name: 1 }, unique: true)
end
