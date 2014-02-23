unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

class PixateConfig
  attr_accessor :framework, :user, :key

  def initialize(config)
    @config = config
  end

  def framework=(path)
    if @framework != path
      @config.unvendor_project(@framework)
      @framework = path
      @config.vendor_project(path, :static, :products => ['PixateFreestyle'], :headers_dir => 'Headers')
      create_code
    end
  end

  private

  def create_code
    license = "PixateFreestyle.initializePixateFreestyle"

    code = <<EOF
# This file is automatically generated. Do not edit.

#{license}

def style(str)
  PixateFreestyle.styleSheetFromSource(str, withOrigin:0)
  PixateFreestyle.applyStylesheets
end
EOF
    pixate_file = './app/pixate_code.rb'
    create_stub(pixate_file, code)
    add_file(pixate_file)
  end

  def create_stub(path, code)
    if !File.exist?(path) or File.read(path) != code
      File.open(path, 'w') { |io| io.write(code) }
    end
  end

  def add_file(path)
    files = @config.files.flatten
    @config.files << path unless files.find { |x| File.expand_path(x) == File.expand_path(path) }
  end
end

module Motion; module Project; class Config

  variable :pixate

  def pixate
    @pixate ||= PixateConfig.new(self)
  end

end; end; end

namespace 'pixate' do
  desc "Create initial stylesheet files"
  task :init do
    if Dir.glob("sass/default.s[ac]ss").empty?
      mkdir_p "sass"
      touch "sass/default.scss"
      App.info 'Create', 'sass/default.scss'
    end

    unless File.exist?("resources/default.css")
      mkdir_p "resources"
      touch "resources/default.css"
      App.info 'Create', 'resources/default.css'
    end
  end

  desc "Compile SASS/SCSS file"
  task :sass do
    unless sass_path = Dir.glob("sass/default.s[ac]ss").first
      warn "Not found `sass/default.scss'"
      exit
    end

    unless File.exist?("resources")
      mkdir_p "resources"
    end

    style = ""
    if ENV['style'].to_s.length > 0
      style = "--style #{ENV['style']}"
    end
    sh "sass #{sass_path} resources/default.css #{style}"
    App.info 'Compile', sass_path
  end
end
