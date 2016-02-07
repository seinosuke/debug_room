module DebugRoom
  class MiniGame
    def initialize(win, height, width)
      @win = win
      @height, @width = height, width

      init_state
      @has_colors = Ncurses.has_colors?
      @exit = false
    end

    # 全てのスレッドを実行する
    def run
      init_state
      threads = []
      threads << drawing_thread
      threads << input_thread
      threads << bullets_thread
      threads.each(&:join)
      @win.clear
      @exit = false
    rescue Interrupt
      @win.clear
      @exit = false
    end

    private

    def init_state
      @player = [@height - 2, (@width / 2)]
      @bullets = Array.new(@width - 1) do
        Array.new(@height) { false }
      end
    end

    # 描画するスレッド
    def drawing_thread
      Thread.new do
        until @exit
          draw_player
          draw_bullets
          @win.border(*([0]*8))
          @win.refresh
          sleep 0.01
          @win.clear
        end
      end
    end

    # 入力を監視するスレッド
    def input_thread
      Thread.new do
        until @exit
          case Ncurses.getch
          when "q".ord then @exit = true
          when Ncurses::KEY_UP
            @player[0] -= 1
            @player[0] = 1 if @player[0] < 3
          when Ncurses::KEY_DOWN
            @player[0] += 1
            @player[0] = @height - 2 if @player[0] > @height - 2
          when Ncurses::KEY_RIGHT
            @player[1] += 1
            @player[1] = @width - 3 if @player[1] > @width - 3
          when Ncurses::KEY_LEFT
            @player[1] -= 2
            @player[1] = 2 if @player[1] < 2
          end
        end
      end
    end

    # 飛んでくる弾を生成したり当たり判定したりするスレッド
    def bullets_thread
      Thread.new do
        until @exit
          @bullets.map! do |row|
            row.unshift rand < 0.02
            row.pop
            row
          end
          @exit = true if gameover?
          sleep 0.1
        end
        @win.move(0, 0)
        @win.addstr("Game Over!\n")
        @win.addstr("Please press any key...\n")
      end
    end

    # 自機を描画
    def draw_player
      @win.attron(Ncurses::COLOR_PAIR(1)) if @has_colors
      @win.move(*@player.zip([-1, 0]).map{ |a, b| a+b })
      @win.addstr("▓")
      @win.move(*@player.zip([0, -1]).map{ |a, b| a+b })
      @win.addstr("▓▓▓")
      @win.attroff(Ncurses::COLOR_PAIR(1)) if @has_colors
    end

    # 飛んでくる弾丸を描画
    def draw_bullets
      @bullets.each_with_index do |row, j|
        row.each_with_index do |bullet, i|
          if bullet
            @win.move(i, j)
            @win.addstr("▓")
          end
        end
      end
    end

    # 弾にあたったらゲームオーバー
    def gameover?
      @player.tap do |i, j|
        break [[i, j], [i, j-1], [i, j+1], [i-1, j]]
          .any? { |pi, pj| @bullets[pj][pi] }
      end
    end
  end
end
