module Htk
  require 'fileutils'
  require 'ap'
  class HTKHMMComposition

    attr_reader :hmms
    attr_accessor :stream_info, :vec_finalizer, :name, :vfloors, :vec_size, :mixture_sets

    def initialize(ex_name,ex_vec_size=-1,ex_stream_info ="",ex_vec_finalizer = "<MFCC>" )
      @name = ex_name
      @stream_info= ex_stream_info || ""
      @vec_finalizer = ex_vec_finalizer
      @vec_size = ex_vec_size
      @hmms = Hash.new
      @mixture_sets = Hash.new
      @vfloors = nil
    end

    def add_hmm(hmm)
      raise "Composition can not contain two Hmms for the same symbol" if @hmms.has_key? hmm.name
      @hmms[hmm.name]=hmm
      @hmms
    end


    def print_status
      puts "Num mixtures: #{@mixture_sets.size}"
      ap @mixture_sets.keys
      puts "Num hmm models: #{@hmms.size}"
      ap @hmms.keys
      @hmms.each_value do |hmm|
        hmm.print_status
      end



    end


    def add_mixture_set_from_prototype(name,prototype)
      tmp_set = HTKHMMMixtureSet.new(prototype.vec_size,name)
      tmp_set.add_detailed_mixture(1.0,prototype.hmms.first[1].states[1][0].mean,prototype.hmms.first[1].states[1][0].variance,prototype.hmms.first[1].states[1][0].gconst)
      add_mixture_set(tmp_set)
    end

    def add_mixture_set(mixture_set)
      @mixture_sets[mixture_set.name]=mixture_set
    end

    def apply_mixture_set_to_model(mixture_set_name,model_name,state_range)

      raise "Indicated mixture set does not exist" unless @mixture_sets.has_key? mixture_set_name

      raise "Indicated hmm does not exist" unless @hmms.has_key? model_name

      @hmms[model_name].apply_symbolic_mixture(mixture_set_name,state_range)


    end

    def write
      File.open(@name,"w") do |file|
        write_header(file)
        write_vfloors(file)
        write_mixtures(file)
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

    def write_mixtures(file)
      @mixture_sets.each_value{|mixture| file.puts mixture.to_s}  unless @mixture_sets.nil? or @mixture_sets.size == 0
    end

    def write_hmms(file)
      @hmms.each_value{|hmm| hmm.write_as_composition(file)}
    end

    def HTKHMMComposition.load(file_name)

      raise "specified file #{file_name} does not exist" unless File.exists? file_name
      file = File.open(file_name,"r")
      lines = HTKHMMComposition.read_lines(file)
      stream_info = HTKHMMComposition.extract_stream_info(lines)
      vec_info = HTKHMMComposition.extract_vec_info(lines)
      if not stream_info.nil? and not vec_info.nil?
        composition = HTKHMMComposition.new(file_name,vec_info[:size],stream_info,vec_info[:finalizer])
        composition.vfloors =  HTKHMMComposition.extract_vfloors(lines)
        composition.mixture_sets = HTKHMMComposition.extract_composition_mixtures(lines,vec_info[:size])
        HTKHMMComposition.extract_models(lines,vec_info[:size]).each_value{|hmm|composition.add_hmm(hmm)}
      else
        raise "Composition did not contain stream and/or vec information"
      end

      return composition
    end

    def HTKHMMComposition.read_lines(file)
      line_array = []
      file.each_line do |line|
        line_array.push line
      end
      return line_array
    end

    def HTKHMMComposition.extract_stream_info(lines)
      lines.each do |line|
        return HTKHMMComposition.extract_stream_info_value(line) if HTKHMMComposition.is_streaminfo_line?(line)
      end
      return ""
    end

    def HTKHMMComposition.extract_vec_info(lines)
      info={:size => -1 , :finalizer => ""}
      lines.each do |line|
        if HTKHMMComposition.is_vecsize_line?(line)
          info[:size] = HTKHMMComposition.extract_vecsize(line)
          info[:finalizer] = HTKHMMComposition.extract_vecfinalizer(line)
          return info
        end
      end
      return nil
    end

    def HTKHMMComposition.extract_vfloors(lines)

      lines.each_with_index do |line,index|
          if VFloors.is_vfloor_name_line? line
            return VFloors.load_from_lines(lines[index..index+2],VFloors.extract_vfloor_name(line))
          end
      end
      return nil
    end

    def HTKHMMComposition.extract_composition_mixtures(lines,feature_space_dim)
      old,current = -1,-1
      old_name,current_name="",""
      mixtures = Hash.new
      lines.each_with_index do |line,index|
        if HTKHMMMixtureSet.is_symbolic_name_line? line or HTKHMMModel.is_name_line? line
          old = current
          current = index
          old_name=current_name
          current_name = HTKHMMMixtureSet.extract_symbolic_name_value(line) unless index == lines.size-1
        end
        if old != -1 and current !=-1
          mixtures[old_name]=HTKHMMMixtureSet.read(lines[old...current],feature_space_dim)
          old = -1
        end
        break if HTKHMMModel.is_name_line? line
      end
      return mixtures
    end

    def HTKHMMComposition.extract_models(lines,feature_space_dim)
      old,current = -1,-1
      old_name,current_name="",""
      models = Hash.new
      lines.each_with_index do |line,index|
        if HTKHMMModel.is_name_line? line or index == lines.size-1
          old = current
          current = index
          old_name=current_name
          current_name = HTKHMMModel.extract_name(line) unless index == lines.size-1
        end
        if old != -1 and current !=-1
          models[old_name]=HTKHMMModel.read(lines[old...current],old_name,feature_space_dim)
          old = -1
        end
      end
      return models
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

    def HTKHMMComposition.extract_stream_info_value(line)
      line.split(" ",2)[1]
    end

    def reestimate_from_training_data(fvar,vvar,training_list,directory,config_file=nil)
      command = HCompVCommand.new do |command|
        command.parameters[:A]=true
        command.parameters[:T]=1
        command.parameters[:m]=true
        command.parameters[:m]=true
        command.parameters[:f]=fvar
        command.parameters[:v]=vvar
        command.parameters[:S]=training_list
        command.parameters[:M]=directory
        command.prototype = @name
      end

      FileUtils.cd(File.dirname(training_list)) do
        write
        command.run(config_file)
      end

      new_model = nil
      FileUtils.cd(directory) do
        new_model =HTKHMMComposition.load(@name)
        new_model.vfloors = VFloors.load("vFloors")
      end

      new_model
    end

    def HTKHMMComposition.compose_from_morpheme_list(ex_name,morpheme_list,prototype,states)

      new_composition= HTKHMMComposition.new(ex_name,prototype.vec_size,prototype.stream_info,prototype.vec_finalizer)
      new_composition.vfloors = prototype.vfloors
      mean = prototype.hmms.first[1].states[1][0].mean
      variance = prototype.hmms.first[1].states[1][0].variance
      gconst = prototype.hmms.first[1].states[1][0].gconst

      morpheme_list.each do |morpheme|
        if states[morpheme].class==Fixnum
          hmm = Htk::HTKHMMModel.strictly_linear_hmm(morpheme,states[morpheme],prototype.vec_size)
        else
          hmm = Htk::HTKHMMModel.ranged_linear_hmm(morpheme,states[morpheme],prototype.vec_size)
        end
        hmm.set_state_distributions(mean,variance,gconst)
        new_composition.add_hmm(hmm)
      end
      return new_composition
    end

    def edit_hmm(edit_chain,directory,morpheme_list,config_file=nil)
     command = HHEdCommand.new do |command|
        command.parameters[:A]=true
        command.parameters[:H]=[@name]
        command.parameters[:M]=directory
        command.edit_chain = edit_chain
        command.list = morpheme_list
     end
      new_model = nil
      FileUtils.cd(directory) do
        write
        command.run(config_file)
        new_model =HTKHMMComposition.load(@name)
      end
      new_model
    end

    def train(iterations,config_file,directory,morpheme_list,training_list_file,training_sample_file)
      command = HERestCommand.new do |command|
        command.parameters[:A]=true
        command.parameters[:T]=1
        command.parameters[:m]=1
        command.parameters[:u]="tmvw"
        command.parameters[:S]= training_list_file
        command.parameters[:I]=[training_sample_file]
        command.parameters[:H]=[File.join(directory,@name)]
        command.parameters[:M]=directory
        command.list = morpheme_list
      end

      new_model = nil
      FileUtils.cd(directory) do
        write
        iterations.times do
          FileUtils.cd(File.dirname(training_list_file)) do
            command.run(config_file)
          end
        end
        new_model =HTKHMMComposition.load(@name)
        new_model.draw
      end
      morpheme_list.restore
      return new_model
    end

    def draw
      @hmms.each_value{|hmm| hmm.draw}
    end

  end
end