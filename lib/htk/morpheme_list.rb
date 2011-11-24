module Htk
  class MorphemeList
   attr_accessor :name

   def initialize
     @name = "List"
     @morphemes = Array.new
   end

   def add(morpheme)
     @morphemes.push(morpheme)
   end

    def each(&proc)
      @morphemes.each &proc
    end

    def restore
      File.open(@name,"w") do |file|
        @morphemes.each{|morpheme| file.puts morpheme}
      end
    end

    def write(file_name=@name)
      File.open(File.basename(file_name),"w") do |file|
        @morphemes.each{|morpheme| file.puts morpheme}
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

    def to_s
      @morphemes.to_s
    end

    def MorphemeList.load(file_name)
      temp=MorphemeList.new
      File.open(file_name,"r").each_line do |line|
           temp.add(line.split[0].strip)
      end
      temp.name = file_name
      return temp
    end

  end
end