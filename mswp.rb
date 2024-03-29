# -*- coding: utf-8 -*-
require './mdarray.rb'

class MSwp
    class Cell
        def initialize
            @inner_state = 0
            @state = 0
        end

        def mine
            @inner_state = -1
        end

        def setNumberOfNeighborMines(n)
            @inner_state = n
        end

        def isMined
            @inner_state == -1
        end

        def getNumberOfNeighborMines
            @inner_state
        end

        def touch
            @state = -1
        end

        def reset
            @state = 0
        end

        def flag
            @state = 1
        end

        def doubt
            @state = 2
        end

        def isTouched
            @state == -1
        end

        def isFlagged
            @state == 1
        end

        def isDoubted
            @state == 2
        end
    end

    class GameOverException < Exception
    end

    class GameClearException < Exception
    end

    def initialize(length, nr_mines)
        @map = MDArray.new(length)
        @nr_mines = nr_mines
        if @nr_mines >= @map.size
            raise ArgumentError.new
        end

        @map.fill { |i| Cell.new }
        @active = false
    end

    def isTouched(pos)
        if ! @active
            return
        end

        @map[pos].isTouched
    end

    def touch(pos)
        if ! @active
            setup(pos)
        end

        cell = @map[pos]
        if cell.isFlagged || cell.isTouched
            return
        end

        if cell.isMined
            @active = false
            raise GameOverException.new
        else
            cell.touch
            @nr_untouched_cells -= 1
            if @nr_untouched_cells == @nr_mines
                raise GameClearException.new
            end

            if cell.getNumberOfNeighborMines == 0
                __touchNeighbors(pos)
            end
        end
    end

    def toggleFlag(pos)
        if ! @active
            return
        end

        cell = @map[pos]
        if cell.isTouched
            return
        end

        if cell.isFlagged
            cell.reset
            @nr_flagged_cells -= 1
        else
            cell.flag
            @nr_flagged_cells += 1
        end
    end

    def toggleDoubt(pos)
        if ! @active
            return
        end

        cell = @map[pos]
        if cell.isTouched
            return
        end

        if cell.isDoubted
            cell.reset
        else
            if cell.isFlagged
                @nr_flagged_cells -= 1
            end
            cell.doubt
        end
    end

    def touchNeighbors(pos)
        if ! @active
            return
        end

        cell = @map[pos]
        if ! cell.isTouched
            return
        end

        nr_flagged_cells = @map.neighbor8_with_index(pos).inject(0) { |sum, (neighbor, i)|
            sum + (neighbor.isFlagged ? 1 : 0)
        }
        if nr_flagged_cells != cell.getNumberOfNeighborMines
            return
        end

        __touchNeighbors(pos)
    end

    def flagNeighbors(pos)
        if ! @active
            return
        end

        cell = @map[pos]
        if ! cell.isTouched
            return
        end

        nr_untouched_cells = @map.neighbor8_with_index(pos).inject(0) { |sum, (neighbor, i)|
            sum + (neighbor.isTouched ? 0 : 1)
        }
        if nr_untouched_cells != cell.getNumberOfNeighborMines
            return
        end

        @map.neighbor8_with_index(pos).each { |(neighbor, i)|
            if ! (neighbor.isTouched || neighbor.isFlagged)
                neighbor.flag
                @nr_flagged_cells += 1
            end
        }
    end

    def neighbors(pos)
        @map.neighbor8_with_index(pos).map { |(neighbor, i)|
            [Marshal.load(Marshal.dump(neighbor)).freeze, i]
        }
    end

    def each
        @map.each_with_index { |cell, pos|
            yield(Marshal.load(Marshal.dump(cell)).freeze, pos)
        }
    end

    attr_reader :active, :nr_mines, :nr_untouched_cells, :nr_flagged_cells

    private

    def setup(pos)
        # 地雷の配置
        (@map.all - [@map[pos]] - (@nr_mines <= @map.size - 3 ** @map.dimension ?
                                   @map.neighbor8_with_index(pos).map { |(cell, i)| cell } :
                                   [])).sort_by { rand }[0...@nr_mines].each { |cell| cell.mine }
        # 近傍地雷数の計算
        @map.each_with_index { |cell, i|
            if ! cell.isMined
                cell.setNumberOfNeighborMines(@map.neighbor8_with_index(i).inject(0) { |sum, (neighbor, j)|
                                                  sum += neighbor.isMined ? 1 : 0
                                              })
            end
        }

        @nr_untouched_cells = @map.size
        @nr_flagged_cells = 0
        @active = true
    end

    def __touchNeighbors(pos)
        @map.neighbor8_with_index(pos).each { |(cell, i)|
            touch(i)
        }
    end
end
