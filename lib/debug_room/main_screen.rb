module DebugRoom
  class MainScreen
    attr_reader :mascot, :exit

    def initialize
      @exit = false # スレッド内ループ脱出用フラグ
      @height, @width = IO::console_size

      Ncurses.initscr
      Ncurses.curs_set(0) # カーソル非表示
      Ncurses.cbreak # RAW(改行を待たない)モードにする
      Ncurses.noecho # エコーしない
      Ncurses.keypad(Ncurses.stdscr, true) # KEY_* 用

      @mascot = Mascot.new(@height - 10, @width - 30)
      @balloon = Balloon.new(5, 35, @height - 18, @width - 40)
      @menu_win = MenuWindow.new(19, 26, @height - 20, @width - 70)
      @menu_win.contents = ["Calendar", "Mini Game", "Exit"]
      color_config
    end

    # 色関連の設定
    def color_config
      if Ncurses.has_colors?
        Ncurses.start_color
        if Ncurses.use_default_colors == Ncurses::OK
          Ncurses.init_pair(1, Ncurses::COLOR_CYAN, -1)
          Ncurses.init_pair(2, -1, Ncurses::COLOR_GREEN)
        end
      end
    end

    # 描画するスレッド
    def drawing_thread
      Thread.new do
        until @exit
          @mascot.draw
          @balloon.draw
          @menu_win.draw

          Ncurses.doupdate
          Ncurses.refresh
          sleep 0.1
        end
      end
    end

    # マスコットの動きとか状態を制御するスレッド
    def mascot_thread
      Thread.new do
        until @exit
          unless @mascot.on_idling || @mascot.on_sleeping
            @mascot.j = @width - @mascot.move_counter[]
          end
          @mascot.count
          sleep (@mascot.on_busy && !@mascot.on_sleeping) ? 0.1 : 0.5
          case Time.now.hour
          when 0..6
            unless @mascot.on_sleeping
              add_message("おやすみ")
              @mascot.on_sleeping = true
            end
          when 7..23
            if @mascot.on_sleeping
              add_message("おはよう")
              @mascot.on_sleeping = false
            end
          end
        end
      end
    end

    # 入力を監視するスレッド
    def input_thread
      Thread.new do
        until @exit
          case Ncurses.getch
          when "q".ord
            @exit = true
          when Ncurses::KEY_UP
            @menu_win.decrease
          when Ncurses::KEY_DOWN
            @menu_win.increase
          when "\n".ord, "\r".ord
            exec_menu
          end
        end
      end
    end

    # マスコットにしゃべらせる
    def add_message(message)
      @mascot.on_idling = true
      @mascot.op = :+
      @balloon.add_message(message)
      # system "../bin/open_jtalk/say.sh #{message}"
      sleep 1
    ensure
      @mascot.on_idling = false
    end

    # エンターキーが押されたら
    # 選択されているメニューを実行する
    def exec_menu
      case @menu_win.contents[@menu_win.selector]
      when "Calendar"
        @menu_win.calendar_mode = true
        @menu_win.contents[@menu_win.selector] = "Clock"
      when "Clock"
        @menu_win.calendar_mode = false
        @menu_win.contents[@menu_win.selector] = "Calendar"
      when "Mini Game"
        add_message("ミニゲームはじまるよ")
        @menu_win.minigame_mode = true
      when "Exit"
        add_message("さよなら")
        @exit = true
      end
    end

    # Ncursesの後処理
    def close
      Ncurses::curs_set(1)
      Ncurses.nocbreak
      Ncurses.echo
      Ncurses.endwin
    end
  end
end
