unless ExampleModel.table_exists?
  ActiveRecord::Schema.define do
    create_table 'example_models', :force => true do |t|
      t.column 'name',    :text
      t.column 'content', :text
    end
  end
end
