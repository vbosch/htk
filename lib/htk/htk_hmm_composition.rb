module Htk
  require 'fileutils'
  class HTKHMMComposition

    attr_accessor :stream_info, :vec_finalizer, :name, :vfloors

    def initialize(ex_name,ex_vec_size=-1,ex_stream_info ="",ex_vec_finalizer = "<MFCC>" )
      @name = ex_name
      @stream_info= ex_stream_info || ""
      @vec_finalizer = ex_vec_finalizer
      @vec_size = ex_vec_size
      @hmms = Hash.new
      @vfloors = nil
    end

    def add_hmm(hmm)
      raise "Composition can not contain two Hmms for the same symbol" if @hmms.has_key? hmm.name
      @hmms[hmm.name]=hmm
      @hmms
    end

    def write
      File.open(@name,"w") do |file|
        write_header(file)
        write_vfloors(file)
        write_hmms(file)
      end
    end

    def write_header(file)
      file.puts "~o "
      file.puts "<STREAMINFO> #{@stream_info}" unless @stream_info.empty?
      file.puts "<VECSIZE> #{@vec_size} #{@vec_finalizer}"
    end

    def write_vfloors(file)
      @vfloors.write_to_descriptor(file) unless @vfloors.nil?
    end

    def write_hmms(file)
      @hmms.each_value{|hmm| hmm.write_as_composition(file)}
    end

    def HTKHMMComposition.load(file_name)

      raise "specified file does not exist" unless File.exists? file_name

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
        elsif VFloors.is_vfloor_name_line? line
          composition = HTKHMMComposition.new(file_name,vec_size,stream_info,vec_finalizer) if composition.nil?
          composition.vfloors = VFloors.load_from_file_descriptor(file,VFloors.extract_vfloor_name(line))
        elsif HTKHMMModel.is_name_line? line
          composition.add_hmm(HTKHMMModel.read(file,HTKHMMModel.extract_name(line),vec_size))
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

    def HTKHMMComposition.compose_from_morpheme_list(morpheme_list,prototype)

    end

    def reestimate_from_training_data(fVar,vVar,training_list,directory,config_file)
      command = HCompVCommand.new do |command|
        command.parameters[:A]=true
        command.parameters[:T]=1
        command.parameters[:m]=true
        command.parameters[:m]=true
        command.parameters[:f]=fVar
        command.parameters[:v]=vVar
        command.parameters[:S]=training_list
        #command.parameters[:M]=directory
        command.prototype = @name
      end


      FileUtils.cd(directory) do
        write
        command.run(config_file)
      end


    end

    def duplicate_gaussians

    end

    def train(iterations)

    end

  end
end