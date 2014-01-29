class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern.is_a?(Regexp) ? pattern : Regexp.new(pattern.to_s)
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
      !!@pattern.match(req.path) &&
      @http_method == req.request_method.downcase.to_sym
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    route_params = parse_route_params(req)
    controller = @controller_class.new(req, res, route_params)
    controller.invoke_action(@action_name.to_sym)
  end

  def parse_route_params(req)
    route_params = {}

    match_data = @pattern.match(req.path)

    match_data.captures.count.times do |n|
      route_params[match_data.names[n].to_sym] = match_data.captures[n]
    end

    route_params
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    instance_eval &proc
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method.to_s) do |pattern, controller_class, action_name|
      @routes << Route.new(pattern,
                           http_method,
                           controller_class,
                           action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    match = nil
    @routes.each do |route|
      match = route if route.matches?(req)
    end
    match
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    matched_route = self.match(req)
    if matched_route
      matched_route.run(req, res)
    else
      res.status = 404
    end
  end
end
