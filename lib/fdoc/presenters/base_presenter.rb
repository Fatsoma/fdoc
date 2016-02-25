require 'erb'
require 'kramdown'
require 'json'
require 'forwardable'

# BasePresenters assist in generating Html for fdoc classes.
# BasePresenters is an abstract class with a lot of helper methods
# for URLs and common text styling tasks (like #render_markdown
# and #render_json)
class Fdoc::BasePresenter
  attr_reader :options

  def initialize(options = {})
    @options = options
  end

  def render_erb(erb_name, binding = get_binding)
    template_path = path_for_template(erb_name)
    template = ERB.new(File.read(template_path), nil, '-')
    template.result(binding)
  end

  def render_markdown(markdown_str, options = {:render_as_span => false})
    if markdown_str
      doc = Kramdown::Document.new(markdown_str, :entity_output => :numeric)
      if options[:render_as_span]
        first_child = doc.root.children.first
        first_child.type = :html_element
        first_child.value = :span
      end
      doc.to_html
    else
      nil
    end
  end

  def get_binding
    binding
  end

  class HTMLBuilder

    def initialize(options = {})
      @options = options.dup
      @buffer  = []

      yield self if block_given?
    end

    def tag(name, *args)
      if block_given?
        options = args.pop || {}
        builder = self.class.new
        yield(builder)
        content = builder.render
      else
        content = args.shift
        options = args.shift || {}
      end

      @buffer << %{<#{name}#{format_options(options)}>#{content}</#{name}>}
    end

    def puts(*args)
      @buffer << args.join
    end

    def render
      @buffer.join
    end

  protected

    def format_options(hash)
      return "" if hash.empty?

      attributes = hash.map do |attribute, value|
       %{#{attribute}="#{value}"}
      end

      %{ #{attributes.join(' ')}}
    end

  end

  def html(*args, &block)
    HTMLBuilder.new(*args, &block).render
  end

  def html_directory
    options[:url_base_path] || options[:html_directory] || ""
  end

  def css_path
    File.join(html_directory, "styles.css")
  end

  def index_path(subdirectory = "")
    html_path = File.join(html_directory, subdirectory)
    if options[:static_html]
      File.join(html_path, 'index.html')
    else
      html_path
    end
  end

  def tag_with_anchor(tag, content, anchor_slug = nil)
    anchor_slug ||= content.downcase.gsub(' ', '_')
    <<-EOS
    <#{tag} id="#{anchor_slug}">
      <a href="##{anchor_slug}" class="anchor">
        #{content}
      </a>
    </#{tag}>
    EOS
  end

  protected

  def path_for_template(filename)
    template_dir  = options[:template_directory]
    template_path = File.join(template_dir, filename) if template_dir
    if template_path.nil? || !File.exists?(template_path)
      template_path = File.join(File.dirname(__FILE__), "../templates", filename)
    end
    template_path
  end
end
