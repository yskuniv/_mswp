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

MAP_WIDTH = ARGV[0].to_i
MAP_HEIGHT = ARGV[1].to_i
MAP_DEPTH = ARGV[2].to_i
MAP_HYPER_DEPTH = ARGV[3].to_i
NR_MINES = ARGV[4].to_i

def print_field(ms, cur)
    Curses.setpos(0, 0)
    str = "Mines: #{ms.nr_mines}, Flagged: #{ms.nr_flagged_cells}, Untouched: #{ms.nr_untouched_cells}, Position: (#{cur.pos.reverse.join(', ')})"
    Curses.attron(Curses.color_pair(2))
    Curses.addstr(str << " " * (Curses.cols - str.length))
    Curses.attroff(Curses::A_COLOR)

    ms.each { |cell, pos|
        offset = ((pos == cur.pos) ?
                  10 : (pos.each_index.inject(true) { |tmp, i|
                            (tmp and (pos[i] - cur.pos[i]).abs <= 1)
                        } ?
                        5 : 0))

        Curses.setpos(pos[2] + (MAP_HEIGHT + 1) * pos[0] + 2, 2 * pos[3] + (MAP_WIDTH + 1) * 2 * pos[1])

        if ms.active
            if cell.isFlagged
                Curses.attron(Curses.color_pair(3 + offset))
                Curses.addstr(" !")
                Curses.attroff(Curses::A_COLOR)
            elsif cell.isDoubted
                Curses.attron(Curses.color_pair(4 + offset))
                Curses.addstr(" ?")
                Curses.attroff(Curses::A_COLOR)
            elsif cell.isTouched
                Curses.attron(Curses.color_pair(1 + offset))
                Curses.addstr((cell.getNumberOfNeighborMines == 0) ?
                                  " ." :
                                  sprintf('%2d', cell.getNumberOfNeighborMines))
                Curses.attroff(Curses::A_COLOR)
            else
                Curses.attron(Curses.color_pair(2 + offset))
                Curses.addstr("  ")
                Curses.attroff(Curses::A_COLOR)
            end
        else
            if cell.isMined
                Curses.attron(Curses.color_pair(5 + offset))
                Curses.addstr(" *")
                Curses.attroff(Curses::A_COLOR)
            else
                Curses.attron(Curses.color_pair(1 + offset))
                Curses.addstr((cell.getNumberOfNeighborMines == 0) ?
                              " ." :
                              sprintf('%2d', cell.getNumberOfNeighborMines))
                Curses.attroff(Curses::A_COLOR)
            end
        end
    }

    Curses.refresh
end

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

ms = MSwp.new([MAP_HYPER_DEPTH, MAP_DEPTH, MAP_HEIGHT, MAP_WIDTH], NR_MINES)
cur = Cursor.new([MAP_HYPER_DEPTH, MAP_DEPTH, MAP_HEIGHT, MAP_WIDTH])

th = Thread.new {
    count = 0
    while true
        Curses.setpos(1, 0)
        Curses.addstr(sprintf('TIME: %02d:%02d', count / 60, count % 60))
        Curses.refresh

        sleep 1
        count += 1
    end
}

begin
    while true
        print_field(ms, cur)

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
rescue MSwp::GameOverException
    th.kill
    print_field(ms, cur)
    Curses.setpos((MAP_HEIGHT + 1) * MAP_HYPER_DEPTH + 2, 0)
    Curses.addstr('Game Over...')
    Curses.refresh
    while Curses.getch != ?q; end
rescue MSwp::GameClearException
    th.kill
    print_field(ms, cur)
    Curses.setpos((MAP_HEIGHT + 1) * MAP_HYPER_DEPTH + 2, 0)
    Curses.addstr('Game Clear!!')
    Curses.refresh
    while Curses.getch != ?q; end
end

Curses.close_screen
