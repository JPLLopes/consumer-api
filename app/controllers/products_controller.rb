class ProductsController < ApplicationController
  include ActionController::Live

  def from_sqlserver
    product_names = Kaminari.paginate_array(Product.group(:product_name).order(:product_name).pluck(:product_name)).page(params[:page]).per(params[:per_page])

    products_per_name = product_names.map do |product_name|
      {
        name: product_name,
        products: Product.where(product_name: product_name).order(:price)
      }
    end

    render json: {products_per_name: products_per_name, total: product_names.total_count}
  end

  def upload
    file = params[:file]

    products_json = JSON.parse(file.read)

    encoded_products_json = products_json.map do |product|
      product.transform_values do |value|
        value.is_a?(String) ? value.force_encoding("ISO-8859-1").encode("UTF-8") : value
      end
    end
    
    product_batches = products_json.each_slice(1000).to_a

    redis = Redis.new
    redis.set("jobs_count", product_batches.size)

    products_json.each_slice(1000) do |batch|
      ProcessProductsJob.perform_async(batch)
    end

    render json: { message: "File uploaded successfully." }, status: :ok
  rescue JSON::ParserError
    render json: { error: "Invalid JSON format" }, status: :unprocessable_entity
  end
end