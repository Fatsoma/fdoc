require 'spec_helper'
require 'nokogiri'

describe Fdoc::SchemaPresenter do
  let(:schema) {
    {
      'description' => 'root description',
      'required' => true,
      'type' => 'object',
      'properties' => {
        'property_name' => {
          'description' => 'Some description text',
          'type' => 'string',
          'required' => true,
          'example' => 'an example'
        }
      }
    }
  }
  subject {
    Fdoc::SchemaPresenter.new(schema, {})
  }

  context '#to_html' do
    it 'should generate valid HTML' do
      html = subject.to_html

      html.should include 'property_name'
      html.should include 'Some description text'
      html.should include 'required'
      html.should include 'string'
      expect {
        Nokogiri::HTML(html) { |config| config.strict }
      }.to_not raise_exception
    end
  end

  context "#to_markdown" do
    it "should generate markdown" do
      markdown = subject.to_markdown
      markdown.should include 'property_name'
      markdown.should include 'Some description text'
      markdown.should include 'required'
      markdown.should include 'string'
    end
  end
end
