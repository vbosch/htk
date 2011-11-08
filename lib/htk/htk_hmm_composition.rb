module Htk
  require 'ruby-debug'
  require 'ap'
  class HTKHMMComposition

    attr_accessor :stream_info, :vec_finalizer, :name

    def initialize(ex_name,ex_vec_size=-1,ex_stream_info ="",ex_vec_finalizer = "<MFCC>" )
      @name = ex_name
      @stream_info= ex_stream_info || ""
      @vec_finalizer = ex_vec_finalizer
      @vec_size = ex_vec_size
      @hmms = Hash.new
    end

    def add_hmm(hmm)
      raise "Composition can not contain two Hmms for the same symbol" if @hmms.has_key? hmm.name
      @hmms[hmm.name]=hmm
      @hmms
    end

    def write
      File.open(@name,"w") do |file|
        write_header(file)
        write_hmms(file)
      end
    end

    def write_header(file)
      file.puts "~o "
      file.puts "<STREAMINFO> #{@stream_info}" unless @stream_info.empty?
      file.puts "<VECSIZE> #{@vec_size} #{@vec_finalizer}"
    end

    def write_hmms(file)
      @hmms.each_value{|hmm| hmm.write_as_composition(file)}
    end

    def HTKHMMComposition.load(file_name)

      composition = nil
      vec_size  = -1
      vec_finalizer,stream_info = ""
      file = File.open(file_name,"r")
      file.each_line do |line|
        if is_vecsize_line? line
          vec_size=extract_vecsize line
          vec_finalizer=extract_vecfinalizer line
        elsif is_streaminfo_line? line
          stream_info=extract_streaminfo line
        elsif is_name_line? line
          name = extract_name(line)
          composition = HTKHMMComposition.new(file_name,vec_size,stream_info,vec_finalizer) if composition.nil?
          composition.add_hmm(HTKHMMModel.read(file,name,vec_size))
        end
      end
      composition
    end

     def HTKHMMComposition.is_vecsize_line?(line)
      line =~ /<VECSIZE>/
    end

    def HTKHMMComposition.extract_vecsize(line)
      vals = line.split(/<|>/).delete_if{|val|val==""}
      vals[vals.index("VECSIZE")+1].to_i
    end

    def HTKHMMComposition.extract_vecfinalizer(line)
      vals = line.split(/<|>/).delete_if{|val|val=="" or val == "\n"}
      vals[vals.index("VECSIZE")+2..vals.size-1].inject(""){|res,val| res +="<#{val}>"}
    end

    def HTKHMMComposition.is_streaminfo_line?(line)
      line =~ /<STREAMINFO>/
    end

    def HTKHMMComposition.extract_streaminfo(line)
      line.split(" ",2)[1]
    end

    def HTKHMMComposition.is_name_line?(line)
      line =~ /~h/
    end

    def HTKHMMComposition.extract_name(line)
      line.split[1].split("\"")[1]
    end

  end
end