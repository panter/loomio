require "#{Rails.root}/plugins/repository"

module Plugins
  class NoCodeSpecifiedError < Exception; end
  Outlet = Struct.new(:plugin, :component, :outlet_name)

  class Base
    attr_accessor :name, :installed
    attr_reader :actions, :events, :outlets, :translations, :enabled

    def self.setup!(name)
      Repository.store new(name).tap { |plugin| yield plugin }
    end

    def initialize(name)
      @name = name
      @translations = {}
      @actions, @events, @outlets = Set.new, Set.new, Set.new
    end

    def enabled=(value)
      @enabled = value.is_a?(TrueClass) || ENV[value]
    end

    def use_class_directory(glob)
      use_directory(glob) { |path| use_class(path) }
    end

    def use_class(path = nil, &block)
      raise NoCodeSpecifiedError.new unless block_given? || path
      proc = block_given? ? block.to_proc : Proc.new { require [Rails.root, :plugins, @name, path].join('/') }
      @actions.add proc
    end

    def extend_class(klass, &block)
      raise NoCodeSpecifiedError.new unless block_given?
      raise NoClassSpecifiedError.new unless klass.present?
      klass.class_eval &block
    end

    def use_asset_directory(glob)
      use_directory(glob) { |path| use_asset(path) }
    end

    def use_translations(path, filename = :client)
      raise NoCodeSpecifiedError.new unless path
      Dir.chdir("plugins/#{@name}") { Dir.glob("#{path}/#{filename}.*.yml").each { |path| use_translation(path) } }
    end

    def use_migration(path = nil, &block)
      raise NoCodeSpecifiedError.new unless block_given? || path
      # ???
    end

    def use_events(&block)
      raise NoCodeSpecifiedError.new unless block_given?
      @events.add block.to_proc
    end

    def use_component(component, outlet: nil)
      [:coffee, :scss, :haml].each { |ext| use_asset("components/#{component}/#{component}.#{ext}") }
      @outlets.add Outlet.new(@name, component, outlet) if outlet
    end

    private

    def use_asset(path)
      file_path = [Rails.root, :plugins, @name, path].join('/')
      dest_path = [Rails.root, :lineman, :app, :plugins, @name, path].join('/')
      dest_folder = dest_path.split('/')[0...-1].join('/') # drop filename so we can create the directory beforehand
      @actions.add Proc.new { FileUtils.mkdir_p(dest_folder) && FileUtils.cp(file_path, dest_path) }
    end

    def use_translation(path)
      @translations.deep_merge! YAML.load_file(path)
    end

    def use_script(path)
      use_asset [path, :coffee].join('.')
    end

    def use_stylesheet(path)
      use_asset [path, :scss].join('.')
    end

    def use_directory(glob)
      Dir.chdir("plugins/#{@name}") { Dir.glob("#{glob}/*").each { |path| yield path } }
    end

  end
end
