module Htk
  class EditChain
    attr_reader :name, :chain

    def initialize(ex_name,ex_chain)
      @name = ex_name
      @chain = ex_chain
    end

    def write
      File.open(File.basename(@name),"w") do |file|
        file.puts @chain
      end
    end

    def clean_up
      FileUtils.rm File.basename(@name)
    end

    def do_with_file(&proc)
      write
      yield unless proc.nil?
      clean_up
    end
  end
end