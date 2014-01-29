require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'


class ControllerBase
  attr_reader :params, :req, :res

  # setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = Params.new(req, route_params)
    @already_built_response = false
  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
  def render_content(body, type)
    raise "Can't render twice" if already_rendered?
    @res.content_type = type
    @res.body = body
    @session.store_session(@res) if @session

    @already_built_response = true
  end

  # helper method to alias @already_built_response
  def already_rendered?
    @already_built_response
  end

  # set the response status code and header
  def redirect_to(url)
    raise "Can't render twice" if already_rendered?
    @res.status = 302
    @res["location"] = url

    @session.store_session(@res) if @session
    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller_name = self.class.to_s.underscore
    string =
    File.read("views/#{controller_name}/#{template_name}.html.erb")
    erb = ERB.new(string)

    render_content(erb.result(binding), "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name.to_sym)
  end
end
