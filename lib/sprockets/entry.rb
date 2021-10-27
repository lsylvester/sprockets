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
        if entry.match?(basename)
          matches << [entry.path, entry.extname_match]
        end
      end

      matches
    end

    def match?(name)
      basename.start_with?(name) &&
      logical_name == name &&
      file?
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
      @logical_name ||= basename.chomp(extname)
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

    def extname_match
      @env.config[:mime_exts][extname]
    end

    def extname
      return @extname if defined?(@extname)

      i = basename.index('.'.freeze)
      while i && i < basename.length - 1
        extname = basename[i..-1]
        if @env.config[:mime_exts][extname]
          @extname = extname
          return @extname
        end

        i = basename.index('.'.freeze, i+1)
      end

      nil
    end
  end
end
