module GenerateHtkLanguageModel
  require 'ruby-debug'
  class MultiSampleStatisticsList
    attr_reader :consolidated_statistics
    def initialize(ex_file_name,ex_filter_list)
      @file_name = ex_file_name
      @sample_filter_list = ex_filter_list
      @samples = Hash.new
      @current_sample=""
      @in_valid_test = false
      @consolidated_statistics = Hash.new{0.0}
    end

    def set_tag_filter(&block)
      @tag_filter = block
    end

    def set_line_reader(&block)
      @line_reader = block
    end

    def read
      File.open(@file_name,"r") do |file|
        while(line=file.gets)
          process_line(line)
        end
      end
      generate_consolidated_statistics
    end

    def each(&block)
      @samples.each_value &block
    end

    def [](sample_name)
      @samples[sample_name]
    end

    def process_line(line)
      unless is_file_header_line?(line)
        if is_test_header_line?(line)
          name = extract_test_name(line)
          if is_in_filter_list?(name) and not processed?(name)
            @in_valid_test = true
            @current_sample=name
            @sample_filter_list.mark_as_processed(name)
            @samples[@current_sample] = SampleStatistics.new(@current_sample)
            @samples[@current_sample].set_tag_filter(&@tag_filter)
            @samples[@current_sample].set_line_reader(&@line_reader)
          end
        elsif is_end_of_test_line?(line)
          @samples[@current_sample].push_line("end") if @in_valid_test
          @in_valid_test = false
        elsif @in_valid_test
          @samples[@current_sample].push_line(line)
        end
      end
    end

    def generate_consolidated_statistics

        @samples.each_value do |sample|
           sample.statistics.each do |key,val|
             @consolidated_statistics[key]+=val
           end
        end
    end

    def is_file_header_line?(line)
      line =~ /#!MLF!#/
    end

    def is_test_header_line?(line)
      line =~ %r{(\*|\w+)/\w+.\w+}
    end

    def is_end_of_test_line?(line)
      line =~ /^\.$/
    end

    def extract_test_name(line)
      temp = line.match(/\/\w+./).to_s
      temp[1...(temp.size-1)]
    end

    def is_in_filter_list?(sample_name)
      @sample_filter_list.include?(sample_name)
    end

    def processed?(sample_name)
      @sample_filter_list.processed?(sample_name)
    end

  end
end