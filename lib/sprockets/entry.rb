module Sprockets
  class Entry
    def initialize(env, path)
      @path = path
      @env = env
    end

    def find_matching_path_for_extensions(logical_name, extensions)
      dirname  = File.dirname(File.join(@path, logical_name))
      basename = File.basename(logical_name)

      *directory_names, filename = logical_name.split('/')
      directory_for_logical_path = directory_names.inject(self){ |directory, path| directory.entries[path] }

      matches = []

      return matches unless directory_for_logical_path

      directory_for_logical_path.entries.keys.each do |entry|
        next unless File.basename(entry).start_with?(basename)
        extname, value = match_path_extname(entry, extensions)
        if basename == entry.chomp(extname)
          filename = File.join(dirname, entry)
          if file?(filename)
            matches << [filename, value]
          end
        end
      end
      matches
    end

    def stat(path)
      @env.stat(path)
    end

    # Public: Like `File.file?`.
    #
    # path - String file path.
    #
    # Returns true path exists and is a file.
    def file?(path)
      if stat = self.stat(path)
        stat.file?
      else
        false
      end
    end

    def entries
      @entries ||= begin
        @env.entries(@path).each_with_object({}) do |path, result|
          result[path] = Entry.new(@env, File.join(@path, path))
        end
      end
    end

    def match_path_extname(path, extensions)
      basename = File.basename(path)

      i = basename.index('.'.freeze)
      while i && i < basename.length - 1
        extname = basename[i..-1]
        if value = extensions[extname]
          return extname, value
        end

        i = basename.index('.'.freeze, i+1)
      end

      nil
    end
  end
end
