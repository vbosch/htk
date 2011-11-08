module Htk
  class MorphemeList

   def initialize
     @morphemes = Array.new
   end

   def add(morpheme)
     @morphemes.push
   end

    def each(&proc)
      @morphemes.each &proc
    end

    def write(file_name)
      File.open(file_name,"w") do |file|
        @morphemes.each{|morpheme| file.puts morpheme}
      end
    end

    def MorphemeList.load(file_name)

      temp=MorphemeList.new
      File.open(file_name,"r").each_line do |line|
           temp.add(line.split[0].trim)
      end
      return temp
    end

  end
end