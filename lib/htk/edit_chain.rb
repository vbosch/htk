module Htk
  class EditChain
    attr_reader :name, :chain

    def initialize(ex_name,ex_chain)
      @name = ex_name
      @chain = ex_chain
    end

    def write
      File.open(@name,"w") do |file|
        file.puts @chain
      end
    end

    def clean_up
      FileUtils.rm @name
    end

    def do_with_file(&proc)
      write
      yield unless proc.nil?
      clean_up
    end
  end
end