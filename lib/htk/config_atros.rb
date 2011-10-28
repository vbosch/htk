module Htk
  require 'ap'
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
  end
end