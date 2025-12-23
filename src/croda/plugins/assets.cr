# Taken from Crystal's stdlib HTTP::StaticFileHandler
# source: https://github.com/crystal-lang/crystal/blob/635ca37a6dc4747cdd5282e6ddf5a5c138fbaf49/src/http/server/handlers/static_file_handler.cr
# adapted to not add a directory browser and use Croda's halt mechanism
module Croda::CrodaPlugins
  module Assets
    module RequestMethods
      def assets
        return unless assets_public_request_method? && assets_public_request_path?
        request_path = URI.decode(@remaining_path)
        assets_check_invalid_request_path!(request_path)

        request_path = Path.posix(request_path)
        expanded_path = request_path.expand("/")

        file_info, file_path = assets_file_info(expanded_path)
        # TODO: if the expanded path does not match the request path, HTTP::StaticFileHandler redirects to the expanded path
        # maybe it's not needed, but we'll see
        # normalized_path = assets_normalize_request_path(request_path, expanded_path, file_info)

        if file_info.nil?
          @response.status = 404
          halt
        end

        if file_info.file?
          assets_serve_file_with_cache(file_info, file_path)
        else
          # Either a directory or not a normal file... just saying not found for now
          @response.status = 404
          halt
        end
      end

      private def assets_serve_file_with_cache(file_info : File::Info, file_path : Path) : Nil
        last_modified = file_info.modification_time
        assets_add_cache_header(last_modified)

        if assets_cache_request?(last_modified)
          @response.status = HTTP::Status::NOT_MODIFIED
          return
        end

        assets_serve_file(file_info, file_path)
      end

      private def assets_serve_file(file_info : File::Info, file_path : Path) : Nil
        @response.content_type = MIME.from_filename(file_path.to_s, "application/octet-stream")

        begin
          File.open(file_path) do |file|
            if range_header = headers["Range"]?
              assets_serve_file_range(file, range_header, file_info)
            else
              @response.headers["Accept-Ranges"] = "bytes"
              assets_serve_file_full(file, file_info)
            end
          end
        rescue File::Error
          # See comment in HTTP::StaticFileHandler#serve_file
          @response.status = 404
          halt
        end
      end

      private def assets_serve_file_range(file : File, range_header : String, file_info : File::Info) : Nil
        range_header = range_header.lchop?("bytes=")
        unless range_header
          @response.headers["Content-Range"] = "bytes */#{file_info.size}"
          @response.status = HTTP::Status::RANGE_NOT_SATISFIABLE
          halt
        end

        ranges = assets_parse_ranges(range_header, file_info.size)
        unless ranges
          @response.status = 400
          halt
        end

        if file_info.size.zero? && ranges.size == 1 && ranges[0].begin.zero?
          @response.status = 200
          halt
        end

        # If any of the ranges start beyond the end of the file, we return an
        # HTTP 416 Range Not Satisfiable.
        # See https://www.rfc-editor.org/rfc/rfc9110.html#section-14.1.2-11.1
        if ranges.any? { |range| range.begin >= file_info.size }
          @response.headers["Content-Range"] = "bytes */#{file_info.size}"
          @response.status = HTTP::Status::RANGE_NOT_SATISFIABLE
          halt
        end

        ranges.map! { |range| range.begin..(Math.min(range.end, file_info.size - 1)) }

        @response.status = HTTP::Status::PARTIAL_CONTENT

        if ranges.size == 1
          range = ranges.first
          file.seek range.begin
          @response.headers["Content-Range"] = "bytes #{range.begin}-#{range.end}/#{file_info.size}"
          IO.copy file, @response.response, range.size
        else
          MIME::Multipart.build(@response.response) do |builder|
            content_type = @response.headers["Content-Type"]?
            @response.headers["Content-Type"] = builder.content_type("byterange")

            ranges.each do |range|
              file.seek range.begin
              headers = HTTP::Headers{
                "Content-Range"  => "bytes #{range.begin}-#{range.end}/#{file_info.size}",
                "Content-Length" => range.size.to_s,
              }
              headers["Content-Type"] = content_type if content_type
              chunk_io = IO::Sized.new(file, range.size)
              builder.body_part headers, chunk_io
            end
          end
        end
      end

      private def assets_serve_file_full(file : File, file_info : File::Info)
        @response.status = 200
        @response.content_length = file_info.size
        IO.copy(file, @response.response)
      end

      # TODO: Optimize without lots of intermediary strings
      private def assets_parse_ranges(header : String, file_size : Int64) : Array(Range(Int64, Int64))?
        ranges = [] of Range(Int64, Int64)
        header.split(",") do |range|
          start_string, dash, finish_string = range.lchop(' ').partition("-")
          return if dash.empty?
          start = start_string.to_i64?
          return if start.nil? && !start_string.empty?
          if finish_string.empty?
            return if start_string.empty?
            finish = file_size
          else
            finish = finish_string.to_i64? || return
          end
          if file_size.zero?
            # > When a selected representation has zero length, the only satisfiable
            # > form of range-spec in a GET request is a suffix-range with a non-zero suffix-length.

            if start
              # This return value signals an unsatisfiable range.
              return [1_i64..0_i64]
            elsif finish <= 0
              return
            else
              start = finish = 0_i64
            end
          elsif !start
            # suffix-range
            start = {file_size - finish, 0_i64}.max
            finish = file_size - 1
          end

          range = (start..finish)
          return unless 0 <= range.begin <= range.end
          ranges << range
        end
        ranges unless ranges.empty?
      end

      private def assets_cache_request?(last_modified : Time) : Bool
        if if_none_match = @request.if_none_match
          match = {"*", @response.headers["Etag"]}
          if_none_match.any? { |etag| match.includes?(etag) }
        elsif if_modified_since = @request.headers["If-Modified-Since"]?
          header_time = HTTP.parse_time(if_modified_since)
          !!(header_time && last_modified <= header_time + 1.second)
        else
          false
        end
      end

      private def assets_add_cache_header(last_modified : Time) : Nil
        @response.headers["Etag"] = %[W/"#{last_modified.to_unix}"]
        @response.headers["Last-Modified"] = HTTP.format_time(last_modified)
      end

      private def assets_normalize_request_path(request_path : Path, expanded_path : Path, file_info : File::Info?) : Path?
        nil
      end

      private def assets_file_info(expanded_path : Path) : Tuple(File::Info?, Path)
        file_path = Assets.public_dir.join(expanded_path.to_kind(Path::Kind.native))

        {File.info?(file_path), file_path}
      end

      private def assets_check_invalid_request_path!(request_path : String) : Nil
        if request_path.includes?('\0')
          @response.status = 400
          halt
        end
      end

      private def assets_public_request_method? : Bool
        method_matches?("GET") || method_matches?("HEAD")
      end

      # this means that while you should put this at the very beginning of the route,
      # if you put it further in, it will match on the path left over after getting there
      private def assets_public_request_path? : Bool
        path = @remaining_path
        result = match(Assets.path)
        return true if result

        # no match but remaining path could have been modified, put it back
        @remaining_path = path
        false
      end
    end

    @@path : String?
    @@public_dir : Path?

    protected def self.path : String
      @@path || raise "Croda::CrodaPlugins::Assets requires 'path' to be set in configuration"
    end

    protected def self.public_dir : Path
      @@public_dir || raise "Croda::CrodaPlugins::Assets requires 'public_dir' to be set in configuration"
    end

    def self.configure(_app : Croda.class, path : String, public_dir : String, **_rest) : Nil
      # remove the leading '/'
      @@path = path.byte_at?(0) == 47 ? path[1..] : path
      @@public_dir = Path.new(public_dir).expand
    end
  end

  register_plugin :assets, Croda::CrodaPlugins::Assets
end
