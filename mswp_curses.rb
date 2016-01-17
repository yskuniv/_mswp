#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'curses'
require './mswp.rb'

class Cursor
    def initialize(length)
        @length = length.freeze
        @pos = Array.new(length.length, 0)
    end

    def move(dim, delta)
        if ! ((0...@length[dim]) === @pos[dim] + delta)
            return
        end

        @pos[dim] += delta
    end

    attr_reader :pos
end

class CursesRenderer
    CellWidth = 2
    CellHeight = 1
    HeaderHeight = 2
    MarginBtwDim = 1

    def initialize(field_hyper_depth, field_depth, field_height, field_width)
        @field_hyper_depth = field_hyper_depth
        @field_depth = field_depth
        @field_height = field_height
        @field_width = field_width

        Curses.init_screen
        Curses.start_color
        Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
        Curses.init_pair(2, Curses::COLOR_BLACK, Curses::COLOR_WHITE)
        Curses.init_pair(3, Curses::COLOR_RED, Curses::COLOR_WHITE)
        Curses.init_pair(4, Curses::COLOR_BLUE, Curses::COLOR_WHITE)
        Curses.init_pair(5, Curses::COLOR_BLACK, Curses::COLOR_RED)
        Curses.init_pair(6, Curses::COLOR_WHITE, Curses::COLOR_BLUE)
        Curses.init_pair(7, Curses::COLOR_BLACK, Curses::COLOR_CYAN)
        Curses.init_pair(8, Curses::COLOR_RED, Curses::COLOR_CYAN)
        Curses.init_pair(9, Curses::COLOR_BLUE, Curses::COLOR_CYAN)
        Curses.init_pair(10, Curses::COLOR_BLACK, Curses::COLOR_RED)
        Curses.init_pair(11, Curses::COLOR_WHITE, Curses::COLOR_GREEN)
        Curses.init_pair(12, Curses::COLOR_BLACK, Curses::COLOR_YELLOW)
        Curses.init_pair(13, Curses::COLOR_RED, Curses::COLOR_YELLOW)
        Curses.init_pair(14, Curses::COLOR_BLUE, Curses::COLOR_YELLOW)
        Curses.init_pair(15, Curses::COLOR_RED, Curses::COLOR_BLACK)
        Curses.noecho
        Curses.curs_set(0)
    end

    def cleanup
        Curses.close_screen
    end

    def print_field(ms, cur_pos)
        header = "Mines: #{ms.nr_mines}, Flagged: #{ms.nr_flagged_cells}, Untouched: #{ms.nr_untouched_cells}, Position: (#{cur_pos.reverse.join(', ')})"
        curses_print header + " " * (Curses.cols - header.length),
                     0, 0, Curses.color_pair(2)

        ms.each do |cell, pos|
            y = CellHeight * ((@field_height + MarginBtwDim) * pos[0] + pos[2]) + HeaderHeight
            x = CellWidth * ((@field_width + MarginBtwDim) * pos[1] + pos[3])

            color_offset = case
                           when pos == cur_pos
                               10
                           when pos.zip(cur_pos).all? { |p, c| (p - c).abs <= 1 }
                               5
                           else
                               0
                           end

            str, attrs = if ms.active
                             case cell
                             when :isFlagged.to_proc
                                 [' !', Curses.color_pair(3 + color_offset)]
                             when :isDoubted.to_proc
                                 [' ?', Curses.color_pair(4 + color_offset)]
                             when :isTouched.to_proc
                                 [(cell.getNumberOfNeighborMines == 0) ?
                                      ' .' : '%2d' % cell.getNumberOfNeighborMines,
                                  Curses.color_pair(1 + color_offset)]
                             else
                                 ['  ', Curses.color_pair(2 + color_offset)]
                             end
                         else
                             case cell
                             when :isMined.to_proc
                                 [' *', Curses.color_pair(5 + color_offset)]
                             else
                                 [(cell.getNumberOfNeighborMines == 0) ?
                                      ' .' : '%2d' % cell.getNumberOfNeighborMines,
                                  Curses.color_pair(1 + color_offset)]
                             end
                         end

            curses_print str, y, x, attrs
        end

        Curses.refresh
    end

    def print_time(min, sec)
        Curses.setpos(1, 0)
        Curses.addstr(sprintf('TIME: %02d:%02d', min, sec))
        Curses.refresh
    end

    def print_gameover
        Curses.setpos(CellHeight * (@field_height + MarginBtwDim) * @field_hyper_depth + 2, 0)
        Curses.addstr('Game Over...')
        Curses.refresh
    end

    def print_gameclear
        Curses.setpos(CellHeight * (@field_height + MarginBtwDim) * @field_hyper_depth + 2, 0)
        Curses.addstr('Game Clear!!')
        Curses.refresh
    end

    private

    def curses_print(str, y, x, attrs)
        Curses.setpos(y, x)
        Curses.attron(attrs)
        Curses.addstr(str)
        Curses.attroff(attrs)
    end
end

FieldWidth = ARGV[0].to_i
FieldHeight = ARGV[1].to_i
FieldDepth = ARGV[2].to_i
FieldHyperDepth = ARGV[3].to_i
NumberOfMines = ARGV[4].to_i

renderer = CursesRenderer.new(FieldHyperDepth, FieldDepth, FieldHeight, FieldWidth)

ms = MSwp.new([FieldHyperDepth, FieldDepth, FieldHeight, FieldWidth], NumberOfMines)
cur = Cursor.new([FieldHyperDepth, FieldDepth, FieldHeight, FieldWidth])

counter_thread = Thread.new do
    count = 0
    loop do
        renderer.print_time(count / 60, count % 60)

        sleep 1
        count += 1
    end
end

begin
    while true
        renderer.print_field(ms, cur.pos)

        case Curses.getch
        when ?q
            break
        when ?h
            cur.move(3, -1)
        when ?l
            cur.move(3, 1)
        when ?k
            cur.move(2, -1)
        when ?j
            cur.move(2, 1)
        when ?H
            cur.move(1, -1)
        when ?L
            cur.move(1, 1)
        when ?K
            cur.move(0, -1)
        when ?J
            cur.move(0, 1)
        when ?\s
            if ms.isTouched(cur.pos)
                ms.touchNeighbors(cur.pos)
            else
                ms.touch(cur.pos)
            end
        when ?f
            if ms.isTouched(cur.pos)
                ms.flagNeighbors(cur.pos)
            else
                ms.toggleFlag(cur.pos)
            end
        when ??
            ms.toggleDoubt(cur.pos)
        end

        # if ms.isTouched(cur.pos)
        #     ms.flagNeighbors(cur.pos)
        #     ms.touchNeighbors(cur.pos)
        # end
    end
rescue MSwp::GameOverException, MSwp::GameClearException => e
    counter_thread.kill

    renderer.print_field(ms, cur.pos)
    case e
    when MSwp::GameOverException
        renderer.print_gameover
    when MSwp::GameClearException
        renderer.print_gameclear
    end

    while Curses.getch != ?q; end
end

renderer.cleanup
