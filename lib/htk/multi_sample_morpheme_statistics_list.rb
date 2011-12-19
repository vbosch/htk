module Htk
  class MultiSampleMorphemeStatisticsList
    def initialize(ex_file_name,ex_filter_list)
      @file_name = ex_file_name
      @sample_filter_list = ex_filter_list
      @samples = Hash.new
      @current_sample=""
      @in_valid_test = false
      @morpheme_statistics=Hash.new
    end

    def set_tag_filter(&block)
      @tag_filter = block
    end

    def set_line_reader(&block)
      @line_reader = block
    end

    def write_sample_event_description(file_name)
      File.open(file_name,"w") do |file|
        @samples.each_value do |sample|
          file.puts sample.to_s
        end
      end
    end

    def morpheme_length_statistics
      @samples.each_value do |sample|
        sample.morpheme_statistics.each do |key,val|
          update_length_statistics(key,val)
        end
      end
      calculate_quartiles
      calculate_means
      calculate_standard_deviations
      return @morpheme_statistics
    end

    def calculate_quartiles
      @morpheme_statistics.each_key do |morpheme_tag|
              @morpheme_statistics[morpheme_tag][:elements].sort!
              @morpheme_statistics[morpheme_tag][:first_quartile]=calculate_quartile(@morpheme_statistics[morpheme_tag][:elements],25)
              @morpheme_statistics[morpheme_tag][:third_quartile]=calculate_quartile(@morpheme_statistics[morpheme_tag][:elements],75)
      end
    end

    def calculate_quartile(elements,percentile)
      n=(((percentile/100.0)*elements.size)+0.5).round
      elements[n-1]
    end

    def calculate_means
      @morpheme_statistics.each_key do |morpheme_tag|
        @morpheme_statistics[morpheme_tag][:mean]=@morpheme_statistics[morpheme_tag][:sum]/@morpheme_statistics[morpheme_tag][:count]
      end
    end

    def calculate_standard_deviations
      @samples.each_value do |sample|
        update_sum_of_squares(sample.sum_of_squares(@morpheme_statistics))
      end
      @morpheme_statistics.each_key do |morpheme_tag|
        @morpheme_statistics[morpheme_tag][:std_dev]=(Math.sqrt(@morpheme_statistics[morpheme_tag][:ssq]/@morpheme_statistics[morpheme_tag][:count])).round
      end
    end

    def update_sum_of_squares(ssq)
      ssq.each do |tag,val|
        raise "Can not update sum of square of uninitialized morpheme" unless @morpheme_statistics.has_key?(tag)
         @morpheme_statistics[tag][:ssq]+=val
      end
    end

    def update_length_statistics(tag,info)
      initialize_category(tag)
      add_elements(tag,info[:elements])
      update_min_statistics(tag,info[:min])
      update_max_statistics(tag,info[:max])
      update_count_statistics(tag,info[:count])
      update_sum_statistics(tag,info[:sum])
    end

    def initialize_category(tag)
      unless @morpheme_statistics.has_key?(tag)
        @morpheme_statistics[tag]={:count=>0,:sum=>0,:min=>-1,:max=>-1,:mean=>-1,:std_dev=>-1,:ssq=>-1,:first_quartile =>-1,:third_quartile=>-1,:elements =>[]}
      end
    end

    def add_elements(tag,elements)
      @morpheme_statistics[tag][:elements].concat(elements)
    end

    def update_min_statistics(tag,length)
      if @morpheme_statistics[tag][:min]>length or @morpheme_statistics[tag][:min] == -1
        @morpheme_statistics[tag][:min]=length
      end
    end

    def update_max_statistics(tag,length)
      if @morpheme_statistics[tag][:max]<length or @morpheme_statistics[tag][:min] == -1
        @morpheme_statistics[tag][:max]=length
      end
    end

    def update_count_statistics(tag,count)
      @morpheme_statistics[tag][:count]+=count
    end

    def update_sum_statistics(tag,length)
      @morpheme_statistics[tag][:sum]+=length
    end


    def read
      File.open(@file_name,"r") do |file|
        while(line=file.gets)
          process_line(line)
        end
      end
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
            @samples[@current_sample] = SampleMorphemeStatistics.new(@current_sample)
            @samples[@current_sample].set_tag_filter(&@tag_filter)
            @samples[@current_sample].set_line_reader(&@line_reader)
          end
        elsif is_end_of_test_line?(line)
          @in_valid_test = false
        elsif @in_valid_test
          @samples[@current_sample].push_line(line)
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
      temp = line.match(/\/\w+[.]+/).to_s
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