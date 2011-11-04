module Htk
  class HTKHMMModel

    SELF_TRANSITION_PROBABILITY=6.000e-01
    NEXT_TRANSITION_PROBABILITY=4.000e-01

    attr_reader :name, :num_states
    attr_accessor :vec_finalizer, :stream_info

    def initialize(ex_name,ex_num_states,ex_feature_space_dimension,&proc)
      @name = ex_name
      @num_states = ex_num_states + 2
      @feature_space_dimension = ex_feature_space_dimension
      @self_prob = SELF_TRANSITION_PROBABILITY
      @next_prob = NEXT_TRANSITION_PROBABILITY
      @stream_info=""
      @vec_finalizer = "<MFCC>"
      yield(self) unless proc.nil?
      initialize_states
    end

    def initialize_states
      @states = Array.new

      @states.push HTKHMMState.start_state(@feature_space_dimension,@num_states)

      1.upto(@num_states-2) do |pos|
        tmp = HTKHMMState.new(pos,@feature_space_dimension){|state| state.self_prob = @self_prob;state.next_prob=@next_prob}
        tmp.initialize_transitions(@num_states,:normal)
        @states.push tmp
      end

      @states.push HTKHMMState.end_state(@feature_space_dimension,@num_states)
    end

    def write
      File.open(@name,"w") do |file|
        write_header(file)
        write_states(file)
        write_transitions(file)
        write_footer(file)
      end
    end

    def write_header(file)
      file.puts "~o "
      file.puts "<STREAMINFO> #{@stream_info}" unless @stream_info.empty?
      file.puts "<VECSIZE> #{@feature_space_dimension} #{@vec_finalizer}"
      file.puts "~h \"#{@name}\""
      file.puts "<BEGINHMM>"
    end

    def write_states(file)
      file.puts "<NUMSTATES> #{@num_states}"

      @states[1...@num_states-1].each do |state|
        file.puts state.distribution_to_s
      end

    end

    def write_transitions(file)
      file.puts "<TRANSP> #{@num_states}"
      @states.each do |state|
        file.puts state.transition_to_s
      end
    end

    def write_footer(file)
      file.puts "<ENDHMM>"
    end

    def HTKHMMModel.load(file_name)

      status = :init
      model = nil
      vec_size,num_states  = -1,-1
      vec_finalizer,stream_info,name = "","",""
      File.open(file_name,"r").each_line do |line|
        case status
          when :init
            if is_vecsize_line? line
              vec_size=extract_vecsize line
              vec_finalizer=extract_vecfinalizer line
            elsif is_streaminfo_line? line
              stream_info=extract_streaminfo line
            elsif is_name_line? line
              name = extract_name line
              raise "internal - external name mismatch" if name != file_name
            elsif is_start_hmm_line? line
              status = :num_states
            end
          when :num_states
            if is_num_states_line? line
              num_states = extract_num_states line
              model = HTKHMMModel.new(name,num_states,vec_size)
              model.vec_finalizer = vec_finalizer
              model.stream_info= stream_info
              status = :read_states
            else
              raise "After a <BEGINHMM> tag line <NUMSTATES> is expected"
            end
          when :read_states


        end

      end
    end

    def is_vecsize_line?(line)
      line =~ /<VECSIZE>/
    end

    def extract_vecsize(line)
      vals = line.split(/<|>/).delete_if{|val|val==""}
      vals[vals.index("VECSIZE")+1].to_i
    end

    def extract_vecfinalizer(line)
      vals = line.split(/<|>/).delete_if{|val|val==""}
      vals[vals.index("VECSIZE")+2..vals.size-1].inject(""){|res,val| res +="<#{val}>"}
    end

    def is_streaminfo_line?(line)
      line =~ /<STREAMINFO>/
    end

    def extract_streaminfo(line)
      line.split(" ",2)[1]
    end

    def is_name_line?(line)
      line =~ /~h/
    end

    def extract_name(line)
      line.split[1].split("\"")[1]
    end

    def is_start_hmm_line?(line)
      line =~ /<BEGINHMM>/
    end

    def is_num_states_line?(line)
      line =~ /<NUMSTATES>/
    end

    def extract_num_states(line)
      line.split[1].to_i
    end

    def is_end_hmm_line?(line)
      line =~ /<ENDHMM>/
    end

    def is_state_initial_line?(line)
      line =~ /<STATE>/
    end

    def extract_state_number(line)
      line.split[1].to_i
    end


    def is_state_variance_line?(line)
      line =~ /<VARIANCE>/
    end

    def is_mean_variance_line?(line)
      line =~ /<MEAN>/
    end

    def extract_values(line,num_values)
      values = line.split
      raise "incorrect number of values found" if values.size != num_values
      values.map{|value| value.to_f}
    end

    def is_state_gconst_line?(line)
      line =~ /<GCONST>/
    end

    def extract_gconst(line)
      line.split[1].to_f
    end

    def is_transition_initial_line?(line)
      line =~ /<TRANSP>/
    end

  end
end