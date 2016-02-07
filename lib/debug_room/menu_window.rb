module DebugRoom
  class MenuWindow
    attr_reader :lines, :cols
    attr_accessor :contents, :selector, :calendar_mode, :minigame_mode

    def initialize(lines, cols, i, j)
      @win = Ncurses::WINDOW.new(lines, cols, i, j)
      @lines = lines
      @cols = cols
      @has_colors = Ncurses.has_colors?
      @selector = 0

      @calendar_mode = false
      @minigame_mode = false
      @minigame = MiniGame.new(@win, @lines, @cols)
    end

    # 全体を描画
    def draw
      @win.clear
      case true
      when @calendar_mode
        print_calendar
      when @minigame_mode
        @minigame.run
        @minigame_mode = false
      else
        print_date
      end
      print_contents
      print_border
      @win.noutrefresh
    end

    # メニュー一覧表示
    def print_contents
      @win.move(10, (@cols / 2) - 4)
      @win.printw("~ Menu ~")

      @contents.each.with_index(6) do |content, i|
        j = (@cols / 2) - (content.size / 2)

        if i == @selector + 6
          @win.attron(Ncurses::COLOR_PAIR(2)) if @has_colors
          @win.move(2*i, j)
          @win.printw(content)
          @win.attroff(Ncurses::COLOR_PAIR(2)) if @has_colors
        else
          @win.move(2*i, j)
          @win.printw(content)
        end
      end
    end

    # ウィンドウの外枠を表示
    def print_border
      @win.border(*([0]*8))
    end

    # カレンダーを表示
    def print_calendar
      `cal`.split("\n").each.with_index(2) do |line, i|
        @win.move(i, 3)
        @win.printw(line)
      end
    end

    # 日時を表示
    def print_date
      now = Time.now
      @win.move(2, (cols / 2.0).to_i - 5)
      @win.printw(now.strftime("%Y/%m/%d"))

      now.strftime("%H").each_char.with_index(1) do |n, j|
        print_num(n.to_i, 4*j)
      end

      j = (@cols / 2) - 1
      COLON.size.times do |i|
        @win.move(i + 4, j)
        @win.printw(COLON[i])
      end

      now.strftime("%M").each_char.with_index(4) do |n, j|
        print_num(n.to_i, 4*j - 1)
      end
    end

    # 数字を表示
    def print_num(num, j)
      5.times do |i|
        @win.move(i + 4, j)
        @win.printw(NUM[num][i])
      end
    end

    def increase
      @selector += 1
      @selector = @contents.size - 1 if @selector >= @contents.size
    end

    def decrease
      @selector -= 1
      @selector = 0 if @selector < 0
    end
  end
end
