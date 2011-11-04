module Htk
  require 'fileutils'
  require 'ostruct'
  class ConfigATROS < OpenStruct
    FILE_NAME="config_ATROS"
    def write

      File.open(FILE_NAME,"w") do |file|
          @table.keys.each do |key|
            file.puts "#{key.to_s.ljust(15)}  = #{self.send(key)}"
          end
      end
    end

    def clean_up
      FileUtils.rm FILE_NAME
    end

    def do_with_file(&proc)
      write
      yield unless proc.nil?
      clean_up
    end

    def name
      FILE_NAME
    end


  end
end