# -*- coding: utf-8 -*-
require './mdarray.rb'

require 'forwardable'

class MSwp
    class IllegalOperationError < StandardError
    end

    class GameOverException < StandardError
    end

    class GameClearException < StandardError
    end

    class Cell
        attr_accessor :mined, :nr_neighbor_mines

        def initialize
            @touched = false
            @mark = nil
        end

        def touch
            raise IllegalOperationError.new if @touched or @mark == :flagged

            if @mined
                raise GameOverException.new
            else
                @touched = true
            end
        end

        def toggle_flag
            toggle_mark(:flagged)
        end

        def toggle_doubt
            toggle_mark(:doubted)
        end

        def flag
            raise IllegalOperationError.new if @touched

            @mark = :flagged
        end

        private

        def toggle_mark(mark)
            raise IllegalOperationError.new if @touched

            @mark = @mark == mark ? nil : mark
        end
    end

    def initialize(length, nr_mines)
        @nr_mines = nr_mines

        @map = MDArray.new(length) { Cell.new }

        raise ArgumentError.new if @nr_mines >= @map.size

        @nr_flagged_cells = 0

        @status = :uninitialized
    end

    def touch(pos)
        raise IllegalOperationError.new if @status == :dead

        if @status == :uninitialized
            setup(pos)
            @status = :initialized
        end

        __touch(pos)
    end

    def toggle_flag(pos)
        raise IllegalOperationError.new if @status == :dead

        @map[pos].toggle_flag
        @nr_flagged_cells += cell.mark == :flagged ? 1 : -1
    end

    def toggle_doubt(pos)
        raise IllegalOperationError.new if @status == :dead

        cell = @map[pos]

        begin
            cell.toggle_doubt
        rescue Cell::IllegalOperationError
            raise IllegalOperationError.new
        end

        # if cell.isFlagged
        #     @nr_flagged_cells -= 1
        # end
        # cell.doubt
    end

    def touch_neighbors(pos)
        raise IllegalOperationError.new if @status == :dead

        cell = @map[pos]

        raise IllegalOperationError.new unless cell.touched

        nr_flagged_cells = @map.neighbor8_with_index(pos).inject(0) { |sum, (neighbor, i)|
            sum + (neighbor.isFlagged ? 1 : 0)
        }
        if nr_flagged_cells != cell.getNumberOfNeighborMines
            return
        end

        __touchNeighbors(pos)
    end

    def flag_neighbors(pos)
        raise IllegalOperationError.new if @status == :dead

        cell = @map[pos]

        raise IllegalOperationError.new unless cell.touched

        nr_untouched_cells = @map.neighbor8_with_index(pos).map { |(c, _)| c.touched ? 0 : 1 }.inject(0, &:+)
        raise IllegalOperationError.new unless nr_untouched_cells == cell.nr_neighbor_mines

        @map.neighbor8_with_index(pos).each { |(c, _)| c.flag }
    end

    # def each
    #     @map.each_with_index { |cell, pos|
    #         yield(Marshal.load(Marshal.dump(cell)).freeze, pos)
    #     }
    # end

    attr_reader :active, :nr_mines, :nr_untouched_cells, :nr_flagged_cells

    private

    def setup(pos)
        mined_cells = (@map.all - [@map[pos]] - (@nr_mines <= @map.size - 3 ** @map.dimension ?
                                                     @map.neighbor8_with_index(pos).map { |(cell, i)| cell } :
                                                     [])).sort_by { rand }[0...@nr_mines]
        # 地雷の配置
        mined_cells.each do |c|
            c.mined = true
        end

        # 近傍地雷数の計算
        @map.each_with_index.reject { |c, _| c.mined  }.each do |cell, i|
            cell.nr_neighbor_mines = @map.neighbor8_with_index(i).map { |c| c.mined ? 1 : 0 }.inject(0, &:+)
        end

        @nr_untouched_cells = @map.size
        # @nr_flagged_cells = 0
        @active = true
    end

    def inner_touch_neighbors(pos)
        @map.eight_neighbors_with_index_at(pos).each do |_, p|
            inner_touch(p)
        end
    end

    def inner_touch(pos)
        cell = @map[pos]

        begin
            cell.touch
        rescue GameOverException
            @status = :dead
            raise GameOverException.new
        end

        @nr_untouched_cells -= 1
        raise GameClearException.new if @nr_untouched_cells == @nr_mines

        __touchNeighbors(pos) if cell.nr_neighbor_mines == 0
    end
end
