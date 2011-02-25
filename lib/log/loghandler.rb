module Log
  require 'rubygems'
  require 'log4r'
  

  # Singleton Class to logging debugging and error states in logfile
  class LibLoghandler
    include Log4r
    attr_accessor :log


    # Check if exists a logging class. If not i'll be create
    # ==Params
    # * +filename+  : Path and filename of logdatei
    # * +log_level+ : Which loglevel are using
    def self.log(options = {:log_level => 1}, filename = "/var/log/xen/xen-gem.log")
      if @log
        return @log
      else
        initialize_logger(filename, options[:log_level])
        return @log
      end
    end

    # Initializing and configuring the logger object
    def self.initialize_logger(file_name, log_level)
      @log = Logger.new("xen_log")

      @log.outputters = Outputter.stdout

      file = FileOutputter.new('fileOutputter', :filename => file_name, :trunc => true)


      @log.add(file)
      @log.level = self.convert_loglevel(log_level)
      format = PatternFormatter.new(:pattern => "[%l] %d :: %m")
      file.formatter = format
    end

    private

    # Converting loglevel configurations for log4r
    def self.convert_loglevel(log_level)
      case log_level
      when 1
        return Log4r::DEBUG
      when 2
        return Log4r::INFO
      when 3
        return Log4r::ERROR
      else
        return Log4r::INFO
      end
    end
  end
end