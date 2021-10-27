module Sprockets
  class Entry
    def initialize(env, path)
      @path = path
      @env = env
    end

    attr_reader :path

    def find_matching_path_for_extensions(logical_name, extensions)
      *directory_names, basename = logical_name.split('/')
      directory_for_logical_path = directory_names.inject(self){ |directory, path| directory&.entries&.[] path }

      matches = []

      return matches unless directory_for_logical_path

      directory_for_logical_path.entries.each_value do |entry|
        next unless entry.basename.start_with?(basename)
        extname, value = entry.match_path_extname
        if basename == entry.basename.chomp(extname)
          if entry.file?
            matches << [entry.path, value]
          end
        end
      end

      matches
    end

    def stat
      @stat ||= @env.stat(path)
    end

    def basename
      @basename ||= File.basename(@path)
    end

    def file?
      stat&.file?
    end

    def logical_name
      basename.chomp(extension_matches[0]) if extension_matches
    end

    def entries
      @entries ||= begin
        if stat&.directory?
          @env.entries(@path).each_with_object({}) do |path, result|
            result[path] = Entry.new(@env, File.join(@path, path))
          end
        else
          {}
        end
      end
    end

    def match_path_extname
      i = basename.index('.'.freeze)
      while i && i < basename.length - 1
        extname = basename[i..-1]
        if value = @env.config[:mime_exts][extname]
          return extname, value
        end

        i = basename.index('.'.freeze, i+1)
      end

      nil
    end
  end
end
