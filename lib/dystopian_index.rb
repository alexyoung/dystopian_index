require 'singleton'

module DystopianIndex
  def self.debug ; true ; end

  def self.included(base)
    base.extend ActiveRecordHook
  end

  def self.enable
    config.reset

    if Object.const_defined? 'ActiveRecord'
      ActiveRecord::Base.class_eval { include DystopianIndex }
    end
  end

  def self.load_models
    config.model_directories.each do |base|
      Dir["#{base}**/*.rb"].each do |file|
        model_name = file.gsub(/^#{base}([\w_\/\\]+)\.rb/, '\1')
      
        next if model_name.nil?
        next if ::ActiveRecord::Base.send(:subclasses).detect { |model|
          model.name == model_name
        }
      
        begin
          model_name.camelize.constantize
        rescue LoadError
          model_name.gsub!(/.*[\/\\]/, '').nil? ? next : retry
        rescue NameError
          next
        end
      end
    end
  end

  def self.index_all
    load_models
    DystopianIndex.config.models.each do |table_name, settings|
      settings[:klass].clear_dystopian_index!
      settings[:klass].index_all
    end
  end

  def self.config
    DystopianIndex::Configuration.instance
  end

  class Builder
    def initialize(model)
      @model    = model
      @fields   = []
      @order_by = nil

      Dir.mkdir(db_path) unless File.exists?(db_path)
      @db_name = File.join db_path, "#{model.table_name}.dys"
    end

    def db_path
      DystopianIndex.config.db_path
    end

    def order_by(field)
      @order_by = field
    end

    def indexes(*fields)
      @fields += fields
    end

    def apply!
      apply_methods!
      add_settings
    end

    private

      def apply_methods!
        @model.class_eval <<-RUBY
          include DystopianIndex::ModelMethods
          after_save :update_dystopian_index
          before_destroy :remove_from_index
        RUBY

        @model.extend DystopianIndex::ModelClassMethods
      end

      def add_settings
        DystopianIndex.config.models[@model.table_name] = {
          :fields   => @fields,
          :db       => @db_name,
          :klass    => @model,
          :order_by => @order_by
        }
      end
  end

  class Configuration
    include Singleton

    attr_accessor :models, :app_root, :model_directories, :disabled, :db_path

    def reset
      self.app_root          = RAILS_ROOT
      self.model_directories = ["#{app_root}/app/models/"]
      self.disabled          = false
      self.db_path           = File.join(self.app_root, 'db', 'indexes')
    end
  end

  module ModelClassMethods
    def dystopian_config
      DystopianIndex.config.models[table_name]
    end

    # == Examples
    #
    # Simple text search:
    #
    #   User.search "name"
    #
    # With pagination:
    #
    #   User.search "name", :page => (params[:page]), :per_page => 10
    #
    def search(*args)
      query = args.first
      return if query.nil?

      args = args.last.is_a?(Hash) ? args.last : {}
      args[:order] = dystopian_config[:order_by]
      paginate_results search_ids(query, args), args
    end

    def search_ids(query, args = {})
      sort_results(with_dystopian_db { |db| db.search(query) })
    end

    def clear_dystopian_index!
      with_dystopian_db do |db|
        db.clear
      end
    end

    def index_all
      find(:all).each do |model|
        model.update_dystopian_index
      end
    end

    def indexer_uses_timestamps?
      return false unless dystopian_config[:order_by]
      order_by = dystopian_config[:order_by].to_s
      if columns_hash[order_by]
        columns_hash[order_by].type == :datetime
      end
    end

    # This will optionally use the date integer (specified by order_by) to sort results
    def sort_results(ids, args = {})
      if indexer_uses_timestamps?
        records = []
        with_dystopian_db do |db|
         records = ids.collect { |id| [id, db.fetch(id)[0..12].to_i] }
        end
        records.sort! { |a, b| a[1] <=> b[1] }
        records.collect { |a| a[0] }
      else
        ids
      end
    end

    def paginate_results(ids, args)
      if args[:page] and defined?(WillPaginate)
        args[:page]     = args[:page].to_i
        args[:per_page] = args[:per_page].to_i

        WillPaginate::Collection.create(args[:page], args[:per_page], ids.size) do |pager|
          start = (args[:page] - 1) * args[:per_page]
          pager.replace(find ids[start, args[:per_page]], :order => dystopian_config[:order_by])
        end
      else
        find ids, args
      end
    end

    def with_dystopian_db
      db = Rufus::Tokyo::Dystopia::Core.new dystopian_config[:db]
      results = yield(db)
    ensure
      db.close if db.respond_to?(:close)
      results
    end
  end

  module ModelMethods
    def dystopian_fields
      self.class.dystopian_config[:fields]
    end

    def with_dystopian_db(&block)
      self.class.with_dystopian_db &block
    end

    def update_dystopian_index
      return if DystopianIndex.config.disabled
      with_dystopian_db do |db|
        db.store id, dystopian_payload
      end
    end

    def remove_from_index
      return if DystopianIndex.config.disabled
      with_dystopian_db do |db|
        db.delete id
      end
    end

    def dystopian_data
      dystopian_fields.collect { |field| read_attribute field }.join("\n")
    end

    def dystopian_timestamps
      if self.class.indexer_uses_timestamps?
        # to_f.to_i in case the value is DateTime
        read_attribute(self.class.dystopian_config[:order_by]).to_f.to_i.to_s.ljust(13)
      else
        ''
      end
    end

    def dystopian_payload
      "#{dystopian_timestamps}#{dystopian_data}"
    end
  end

  module ActiveRecordHook
    def dystopian_index(&block)
      DystopianIndex.config.models ||= {}

      builder = DystopianIndex::Builder.new(self)
      builder.instance_eval(&block)
      builder.apply!
    end
  end
end
