module Htk
  class SampleMorphemeStatistics
    attr_reader :morpheme_statistics
    def initialize(ex_name)
      @name= ex_name
      @lines = Array.new
      @morpheme_statistics=Hash.new
    end

    def set_tag_filter(&block)
      @tag_filter = block
    end

    def set_line_reader(&block)
      @line_reader = block
    end

    def push_line(line)
      tmp = @line_reader.call(line)
      update_length_statistics(tmp) unless @tag_filter.call(tmp)
      @lines.push(tmp) unless @tag_filter.call(tmp)
    end

    def sum_of_squares(morpheme_statistics)
      @lines.each do |info|
        length =  (info[:end] - info[:start]).abs
        update_sum_of_square_statistics(info[:tag],(length-morpheme_statistics[info[:tag]][:mean])**2)
      end
      return sum_of_squares_summary
    end

    def sum_of_squares_summary
      tmp = Hash.new
      @morpheme_statistics.each do |tag,val|
        tmp[tag]=val[:ssq]
      end
      return tmp
    end

    def update_length_statistics(info)
      initialize_category(info)
      length =  (info[:end] - info[:start]).abs
      add_element(info[:tag],length)
      update_min_statistics(info[:tag],length)
      update_max_statistics(info[:tag],length)
      update_count_statistics(info[:tag])
      update_sum_statistics(info[:tag],length)
    end


    def initialize_category(info)
      unless @morpheme_statistics.has_key?(info[:tag])
        @morpheme_statistics[info[:tag]]={:count=>0,:sum=>0,:min=>-1,:max=>-1,:ssq=>0, :elements => []}
      end
    end

    def add_element(tag,element)
      @morpheme_statistics[tag][:elements].push(element)
    end

    def update_sum_of_square_statistics(tag,ssq)
      @morpheme_statistics[tag][:ssq]+=ssq
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

    def update_count_statistics(tag)
      @morpheme_statistics[tag][:count]+=1
    end

    def update_sum_statistics(tag,length)
      @morpheme_statistics[tag][:sum]+=length
    end

    def to_s
      "#{@name} #{@lines.count}"
    end


  end
end