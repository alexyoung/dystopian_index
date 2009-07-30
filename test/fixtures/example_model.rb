class ExampleModel < ActiveRecord::Base
  dystopian_index do
    indexes :content
    indexes :name
    order_by :created_at
  end
end
