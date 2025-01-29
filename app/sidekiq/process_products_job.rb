class ProcessProductsJob
  include Sidekiq::Job

  def perform(product_array)
    begin
      keys_to_exclude = [
        "title", "universeTitle", "title2", "title3", "site_id", "variation", "availability", "wasPrice", "isbundle",
        "delivery", "image", "modified", "deliveryprice", "ismarketplace", "marketplaceseller", "site", "referenceId"
      ]

      new_key_mapping = {
        "sku"=> "product_id",
        "model"=> "product_name",
        "categoryId"=> "product_category_id"
      }

      filtered_products = product_array.filter_map do |product|
        country_code_regex = /\b[a-zA-Z]{2}\b\s*/i
        
        shop_name = product["ismarketplace"] == true ? product["marketplaceseller"] : product["site"]
        shop_name = shop_name.gsub("'", "''").gsub(country_code_regex, '').strip
        
        country = product["country"].gsub(country_code_regex, '').strip
        
        product.except!(*keys_to_exclude)
        product.transform_keys! { |key| new_key_mapping[key] || key }
        product.transform_values! { |value| value.is_a?(String) ? value.force_encoding("ISO-8859-1").encode("UTF-8") : value }

        product["shop_name"] = shop_name
        product["country"] = country

        product
      end

      filtered_products.each do |product|
        sql = <<-SQL
          MERGE INTO products AS target
          USING (SELECT 
            '#{product['product_id']}' AS product_id, 
            '#{product['country']}' AS country, 
            '#{product['brand']}' AS brand, 
            '#{product['product_name']}' AS product_name, 
            '#{product['shop_name']}' AS shop_name, 
            '#{product['product_category_id']}' AS product_category_id, 
            '#{product['price']}' AS price, 
            '#{product['url']}' AS url,
            '#{product['created_at']}' AS created_at,
            '#{product['updated_at']}' AS updated_at
          ) AS source
          ON target.product_id = source.product_id 
            AND target.country = source.country
            AND target.shop_name = source.shop_name
          WHEN MATCHED THEN
            UPDATE SET 
              brand = source.brand,
              product_name = source.product_name,
              product_category_id = source.product_category_id,
              price = source.price,
              url = source.url,
              updated_at = '#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}'
          WHEN NOT MATCHED THEN
            INSERT (product_id, country, brand, product_name, shop_name, product_category_id, price, url, created_at, updated_at) 
            VALUES (source.product_id, source.country, source.brand, source.product_name, source.shop_name, source.product_category_id, source.price, source.url, '#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}', '#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}');
        SQL

        result = ActiveRecord::Base.connection.execute(sql)
      end

      operations = filtered_products.map do |product|
        current_time = Time.now

        {
          update_one: {
            filter: { product_id: product['product_id'], country: product['country'], shop_name: product['shop_name'] },
            update: {
              "$set": {
                brand: product['brand'],
                product_name: product['product_name'],
                product_category_id: product['product_category_id'],
                price: product['price'],
                url: product['url'],
                updated_at: current_time
              },
              "$setOnInsert": {
                created_at: current_time
              }
            },
            upsert: true
          }
        }
      end

      ProductMdb.collection.bulk_write(operations)

      redis = Redis.new
      redis.decr("jobs_count")

      job_count = redis.get("jobs_count").to_i

      if job_count == 0 
        ActionCable.server.broadcast 'products_channel', "DONE"
      end

    rescue => e
      puts "Error: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end
