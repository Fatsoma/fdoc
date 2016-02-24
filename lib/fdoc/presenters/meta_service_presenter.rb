# HtmlPresenter for Fdoc::MetaService
class Fdoc::MetaServicePresenter < Fdoc::HtmlPresenter
  attr_reader :meta_service

  def initialize(meta_service, options = {})
    super(options)
    @meta_service = meta_service
  end

  def to_html
    render_erb('meta_service.html.erb')
  end

  def services
    @services ||= meta_service.services.
      sort_by(&:name).
      map do |service|
        Fdoc::ServicePresenter.new(service, options)
      end
  end

  def description
    render_markdown(meta_service.description)
  end

  def discussion
    render_markdown(meta_service.discussion)
  end

  private

  def presenter_from_endpoint(endpoint)
    service_presenter = Fdoc::ServicePresenter.new(endpoint.service)

    presenter = Fdoc::EndpointPresenter.new(endpoint,
      options.merge(:prefix => (service_presenter.slug_name + "/")))
    presenter.service_presenter = service_presenter
    presenter
  end
end
