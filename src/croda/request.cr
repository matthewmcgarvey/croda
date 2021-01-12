class Croda::Request
  def initialize(@request : HTTP::Request)
  end

  forward_missing_to @request
end
