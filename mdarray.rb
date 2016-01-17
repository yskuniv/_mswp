class MDArray
    class InnerMDArray
        def initialize(length, index_prefix = [], &block)
            if length.length == 0
                @value = block.call(index_prefix) if block
            else
                length_head = length.first
                sub_length = length.drop(1)
                @array = (0...length_head).map { |i| InnerMDArray.new(sub_length, index_prefix + [i], &block) }
            end

            nil
        end

        def [](index)
            if index.length == 0
                @value
            else
                index_head = index.first
                sub_mdindex = index.drop(1)
                @array[index_head][sub_mdindex]
            end
        end

        def []=(index, value)
            if index.length == 0
                @value = value
            else
                index_head = index.first
                sub_mdindex = index.drop(1)
                @array[index_head][sub_mdindex] = value
            end
        end

        def each_with_mdindex(index_prefix, &block)
            unless @array
                block.call([@value, index_prefix])
            else
                @array.each_with_index do |sub_mdarray, i|
                    sub_mdarray.each_with_mdindex(index_prefix + [i], &block)
                end
            end
        end

        def neighbor4_with_mdindex(index, index_prefix, &block)
            if index.length == 0
                []
            else
                index_head = index.first
                sub_mdindex = index.drop(1)
                @array[index_head].neighbor4_with_mdindex(sub_mdindex, index_prefix + [index_head], &block)
                [-1, 1].map { |d| index_head + d }.select { |i| (0...@array.length).include?(i) }.each do |i|
                    block.call([@array[i][sub_mdindex], index_prefix + [i] + sub_mdindex])
                end
            end
        end

        def neighbor8_and_self_with_mdindex(index, index_prefix, &block)
            if index.length == 0
                @value
            else
                index_head = index.first
                sub_mdindex = index.drop(1)
                (-1..1).map { |d| index_head + d }.select { |i| (0...@array.length).include?(i) }.each do |i|
                    @array[i].neighbor8_and_self_with_mdindex(sub_mdindex, index_prefix + [i], &block)
                end
            end
        end
    end

    def initialize(length, &block)
        @inner_mdarray = InnerMDArray.new(length, &block)
    end

    # def dimension
    #     @length.length
    # end

    # def is_valid_index(index)
    #     index.length == dimension && __is_valid_index(index)
    # end

    # attr_reader :length, :size
end

c = -1
a = MDArray::InnerMDArray.new([5, 5]) { |mi| c += 1 }

a.each_with_mdindex do |e, mi|
    puts "#{mi}: #{e}"
end

a.neighbor4_with_mdindex([3, 3]) do |e, mi|
    puts "#{mi}: #{e}"
end

a.neighbor4_with_mdindex([0, 3]) do |e, mi|
    puts "#{mi}: #{e}"
end
