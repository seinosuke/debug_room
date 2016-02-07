module DebugRoom
  class Balloon
    attr_reader :lines, :cols

    def initialize(lines, cols, i, j)
      @win = Ncurses::WINDOW.new(lines, cols, i, j)
      @lines = lines
      @cols = cols
      @messages = []
    end

    def add_message(message)
      @messages << message
      @messages.shift if @messages.size > 3
    end

    def draw
      @win.clear
      @messages.each do |message|
        @win.printw("\n")
        @win.printw("  > #{message}")
      end
      @win.border(*([0]*8))
      @win.noutrefresh
    end
  end
end
