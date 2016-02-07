module DebugRoom
  class Mascot
    attr_accessor \
      :i, :j, \
      :on_idling, :on_busy, :on_sleeping, \
      :move_counter, :op

    def initialize(i, j)
      @i, @j = i, j
      @height = MASCOT_NORMAL[0].size
      @width = MASCOT_NORMAL[0].size
      @has_colors = Ncurses.has_colors?
      @op = :+
      @on_idling = false
      @on_busy = false
      @on_sleeping = false
      set_counter
    end

    def set_counter
      # 0..(max-1) を繰り返し返すクロージャ
      counter = ->(max) do
        n = max - 1
        -> { n == max - 1 ? n = 0 : n += 1 }
      end
      @mascot_normal_counter = counter[MASCOT_NORMAL.size]
      @mascot_sleeping_counter = counter[MASCOT_SLEEPING.size]
      @sweat_counter = counter[SWEAT.size]
      @zzz_counter = counter[ZZZ.size]
      count

      # マスコットを動かす用のクロージャ
      @move_counter = ->(min, max) do
        n = min - 1; @op = :+
        -> do
          @op = :+ if n == min
          @op = :- if n == max
          eval "n #{@op}= 1"
        end
      end[30, 40]
    end

    # カウンターを進める
    def count
      @normal_n = @mascot_normal_counter[]
      @sleeping_n = @mascot_sleeping_counter[]
      @sweat_n = @sweat_counter[]
      @zzz_n = @zzz_counter[]
    end

    # マスコットの部分だけクリア
    def clear
      MASCOT_NORMAL[0].size.times do |di|
        Ncurses.move(@i + di, @j - 3)
        Ncurses.printw("#{" "*26}")
      end
    end

    def draw
      clear
      case true
      when @on_sleeping then draw_sleeping
      when @on_busy     then draw_busy
      else                   draw_normal
      end
    end

    def draw_normal
      @height.times do |di|
        Ncurses.move(@i + di, @j)
        Ncurses.printw(MASCOT_NORMAL[@normal_n][di]
          .send(@op == :+ ? :itself : :reverse))
      end
      add_eraser
    end

    def draw_busy
      @height.times do |di|
        Ncurses.move(@i + di, @j)
        Ncurses.printw(MASCOT_NORMAL[@normal_n][di]
          .send(@op == :+ ? :itself : :reverse))
      end
      add_sweat
    end

    def draw_sleeping
      @height.times do |di|
        Ncurses.move(@i + di, @j)
        Ncurses.printw(MASCOT_SLEEPING[@sleeping_n][di]
          .send(@op == :+ ? :itself : :reverse))
      end
      add_zzz
    end

    # エフェクトを消すエフェクト
    def add_eraser
      j = @j + @width * 3
      ERASER.each_with_index do |str, di|
        Ncurses.move(@i + di, j)
        Ncurses.printw(str)
      end
    end

    # 汗を描画する
    def add_sweat
      Ncurses.attron(Ncurses::COLOR_PAIR(1)) if @has_colors
      j = @j + @width * 3
      SWEAT[0].size.times do |di|
        Ncurses.move(@i + di, j)
        Ncurses.printw(SWEAT[@sweat_n][di])
      end
      Ncurses.attroff(Ncurses::COLOR_PAIR(1)) if @has_colors
    end

    # zzzを描画する
    def add_zzz
      Ncurses.attron(Ncurses::A_BOLD)
      j = @j + @width * 3
      ZZZ[0].size.times do |di|
        Ncurses.move(@i + di, j)
        Ncurses.printw(ZZZ[@zzz_n][di])
      end
      Ncurses.attroff(Ncurses::A_BOLD)
    end
  end
end
