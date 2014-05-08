class MDArray
    class ElemRef
        def initialize(array, index)
            @array = array
            @index = index
        end

        def +@
            @array[@index]
        end

        def <<(value)
            @array[@index] = value
        end
    end

    def initialize(length, init = nil)
        if length.length == 0
            raise ArgumentError.new "Zero-dimensioanl array is unsupported"
        end

        @length = length.freeze
        @array = create_array(@length, init)
        @size = @length.inject(1) { |ret, val|
            ret * val
        }
    end

    def dimension
        @length.length
    end

    def is_valid_index(index)
        index.length == dimension && __is_valid_index(index)
    end

    def all
        __all
    end

    def indexes
        __indexes
    end

    def [](index)
        if ! is_valid_index(index) then
            raise IndexError.new
        end

        +ref_at(index)
    end

    def []=(index, value)
        if ! is_valid_index(index) then
            raise IndexError.new
        end

        ref_at(index) << value
    end

    def each
        __each_with_index { |ref, index|
            yield(+ref)
        }
    end

    def each_with_index
        __each_with_index { |ref, index|
            yield(+ref, index)
        }
    end

    def fill
        __each_with_index { |ref, index|
            ref << yield(index)
        }
    end

    def neighbor4_with_index(index)
        if ! is_valid_index(index) then
            raise IndexError.new
        end

        __neighbor4_with_index(index)
    end

    def neighbor8_with_index(index)
        if ! is_valid_index(index) then
            raise IndexError.new
        end

        tmp = neighbor8_and_self_with_index(index)
        tmp.delete([+ref_at(index), index])
        tmp
    end

    attr_reader :length, :size

    private

    def create_array(length, init)
        if length.length == 1
            Array.new(length[0], init)
        else
            Array.new(length[0]) {
                create_array(length[1..-1], init)
            }.freeze
        end
    end

    def __is_valid_index(index, array = @array)
        if index.length == 0
            true
        else
            (0...array.length) === index[0] && __is_valid_index(index[1..-1], array[index[0]])
        end
    end

    def __all(array = @array, c = 0)
        if c == dimension
            [array]
        else
            array.inject([]) { |buf, elem|
                buf + __all(elem, c + 1)
            }
        end
    end

    def __indexes(length = @length, elem_index = [])
        if length.length == 0
            [elem_index.freeze]
        else
            (0...length[0]).inject([]) { |buf, i|
                buf + __indexes(length[1..-1], elem_index + [i])
            }
        end
    end

    def ref_at(index, array = @array)
        if index.length == 1
            ElemRef.new(array, index[0])
        else
            ref_at(index[1..-1], array[index[0]])
        end
    end

    def __each_with_index(array = @array, elem_index = [], &block)
        if elem_index.length == dimension - 1
            array.length.times { |i|
                block.call(ElemRef.new(array, i), (elem_index + [i]).freeze)
            }
        else
            array.length.times { |i|
                __each_with_index(array[i], elem_index + [i], &block)
            }
        end
    end

    def __neighbor4_with_index(index, array = @array, elem_index = [])
        if index.length == 1
            [index[0] - 1, index[0] + 1].delete_if { |i|
                ! ((0...array.length) === i)
            }.inject([]) { |ret, i|
                ret + [[array[i],
                        (elem_index + [i]).freeze]]
            }
        else
            [index[0] - 1, index[0], index[0] + 1].delete_if { |i|
                ! ((0...array.length) === i)
            }.inject([]) { |ret, i|
                ret + (i == index[0] ?
                       __neighbor4_with_index(index[1..-1],
                                              array[i],
                                              elem_index + [i]) :
                       [[+ref_at(index[1..-1], array[i]),
                         (elem_index + [i] + index[1..-1]).freeze]])
            }
        end
    end

    def neighbor8_and_self_with_index(index, array = @array, elem_index = [])
        if index.length == 0
            [[array, elem_index.freeze]]
        else
            [index[0] - 1, index[0], index[0] + 1].delete_if { |i|
                ! ((0...array.length) === i)
            }.inject([]) { |ret, i|
                ret + neighbor8_and_self_with_index(index[1..-1],
                                                    array[i],
                                                    elem_index + [i])
            }
        end
    end
end
