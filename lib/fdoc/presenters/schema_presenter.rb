# An BasePresenter for a JSON Schema fragment. Like most JSON
# schema things, has a tendency to recurse.
class Fdoc::SchemaPresenter < Fdoc::BasePresenter
  FORMATTED_KEYS = %w(
    description
    type
    required
    deprecated
    default
    format
    example
    enum
    items
    properties
  )

  def initialize(schema, options)
    super(options)
    @schema = schema
  end

  # Attribute Helpers

  def description
    @schema["description"]
  end

  def format
    @schema["format"]
  end

  def type
    @schema["type"]
  end

  def request?
    options[:request]
  end

  def nested?
    options[:nested]
  end

  def deprecated?
    @schema["deprecated"]
  end

  def required?
    @schema["required"]
  end

  def unformatted_keys
    @schema.keys - FORMATTED_KEYS
  end

  def schema_slug(key, property)
    "#{key}-#{property.hash}"
  end

  # Builders

  def to_html
    html do |output|
      output.tag(:span, 'Deprecated', :class => 'deprecated') if deprecated?
      output.tag(:div, :class => 'schema') do |schema|
        schema.tag(:ul) do |list|
          unformatted_keys.each do |key|
            list.tag(:li, "#{key}: #{@schema[key]}")
          end

          list.puts(enum_html)
          list.puts(items_html)
          list.puts(properties_html)
        end
      end
    end
  end

  def to_markdown(prefix = "")
    md = StringIO.new
    md << 'Deprecated' if deprecated?
    unformatted_keys.each do |key|
      md << "\n#{prefix}* #{key} #{@schema[key]}"
    end
    md << "\n#{@schema['enum']}"
    if items = @schema["items"]
      md << "\n#{prefix}* Items"
      if items.kind_of?(Array)
        items.compact.each do |item|
          md << Fdoc::SchemaPresenter.new(item, options.merge(:nested => true)).to_markdown(prefix + "\t")
        end
      else
        md << Fdoc::SchemaPresenter.new(@schema["items"], options.merge(:nested => true)).to_markdown(prefix + "\t")
      end
    end
    if properties = @schema["properties"]
      properties.each do |key, property|
        next if property.nil?

        schema = Fdoc::SchemaPresenter.new(property, options.merge(:nested => true))

        tags = []
        tags << schema.description if schema.description
        tags << '_required_' if schema.nested? && schema.required?
        tags << "_#{format}_" if schema.format
        tags << "_#{schema.type_html}_" if schema.type_html
        tags_string = tags.empty? ? '' : ' ' + tags.join(' ')

        md << "\n#{prefix}* __#{key}__:#{tags_string}"
        md << schema.to_markdown(prefix + "\t")
      end
    end
    md.string
  end

  def type_html
    if type.kind_of?(Array)
      html do |output|
        output.tag(:ul) do |list|
          type.each do |t|
            if t.kind_of?(Hash)
              list.tag(:li, self.class.new(t, options).to_html)
            else
              list.tag(:li, t)
            end
          end
        end
      end
    elsif type != "object"
      type
    end
  end

  def enum_html
    return unless enum = @schema["enum"]

    list = enum.map do |e|
      "<tt>#{e}</tt>"
    end.join(", ")

    html do |output|
      output.tag(:li, "Enum: #{list}")
    end
  end

  def items_html
    return unless items = @schema["items"]

    html do |output|
      output.tag(:li) do |list|
        list.tag(:span, 'Items', :class => 'items')
        sub_options = options.merge(:nested => true)

        if items.kind_of?(Array)
          items.compact.each do |item|
            list.puts(self.class.new(item, sub_options).to_html)
          end
        else
          list.puts(self.class.new(items, sub_options).to_html)
        end
      end
    end
  end

  def properties_html
    return unless properties = @schema["properties"]

    html do |output|
      properties.each do |key, property|
        next if property.nil?

        schema = self.class.new(property, options.merge(:nested => true))

        output.tag(:li) do |list|
          tags = html do |tags|
            tags.tag(:span, "required", :class => 'required') if schema.nested? && schema.required?
            tags.puts " "
            tags.tag(:span, "#{schema.format}", :class => 'format') if schema.format
            tags.puts " "
            tags.tag(:span, "#{schema.type_html}", :class => 'type') if schema.type_html
          end

          list.puts(tag_with_anchor('span', "<tt>#{key}</tt> - #{render_markdown(schema.description)} #{tags}", schema_slug(key, property)))
          list.puts(schema.to_html)
        end
      end
    end
  end
end
