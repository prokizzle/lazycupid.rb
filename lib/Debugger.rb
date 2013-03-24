class Debugger

    def initialize(args)
      path      = args[ :path]
      @filename = "#{path}/debug.log"
    end

    def log_error(e, code)
        unless File.exists?(@filename)
              File.open(@filename, "w") do |f|
                f.write(config.to_yaml)
              end
        end

        log_data = "#{e.message}, #{e.backtrace}, #{code}"

        File.open(@filename, "w") do |f|
          f.write(log_data)
        end

    end



end