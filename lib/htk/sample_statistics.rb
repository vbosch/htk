module GenerateHtkLanguageModel
  require 'ap'
  class SampleStatistics
    attr_reader :statistics
    def initialize(ex_name)
      @name= ex_name
      @last_read=:EMPTY
      @last_state = []
      @statistics = Hash.new{0.0}
    end

    def set_tag_filter(&block)
      @tag_filter = block
    end

    def set_line_reader(&block)
      @line_reader = block
    end

    def push_line(line)
      line_type = @line_reader.call(line)

      unless @tag_filter.call(line_type)

        at = :NORMAL
        at = :START if @last_read == :EMPTY

        if line_type == :END
          at = :END
          current_state = [at,@last_read]
          @statistics[@last_state]-=1.0
          @statistics[current_state]+=1.0
          @statistics[@last_transition]-=1
          @statistics[[@last_transition[0],current_state]]+=1

        else
          @statistics[:COUNT]+=1.0
          current_state = [at,line_type]
          @statistics[current_state]+=1.0
          @statistics[[@last_state,current_state]]+=1.0 if at != :START
          @last_transition=[@last_state,current_state]
          @last_state = current_state
          @last_read = line_type
        end
      end
    end

    def write(file_name)
      File.open(file_name,"w") do |file|

      end
    end


  end
end