require 'uri'

class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  def initialize(req, route_params = {})
    query_string = req.query_string
    post_body = req.body

    @params = {}

    if query_string
      @params.merge!(parse_query(query_string))
    elsif post_body
      @params.merge!(parse_body(post_body))
    else
      @params.merge!(route_params)
    end
  end

  def [](key)
    @params[key]
  end

  def to_s
    @params.to_s
  end

  private

  def parse_query(string)
    parse_www_encoded_form(string)
  end

  def parse_body(body)
    parse_www_encoded_form(body)
  end

  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    query_array = URI.decode_www_form(www_encoded_form)

    query_array.map do |pair|
      if pair[0].include?("]")
        pair[0] = parse_key(pair[0])
      end
    end

    parsed = {}
    query_array.each do |pair|
      if pair[0].is_a?(Array)
        parsed.merge!(nest(pair[0], pair[1]))
      else
        parsed[pair[0]] = pair[1]
      end
    end

    parsed
  end

  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.split(/\]\[|\[|\]/)
  end

  def nest(array, value)
    until array.empty?
      hash = {}
      hash[array.pop] = value
      value = hash.dup
    end

    hash
  end
end
