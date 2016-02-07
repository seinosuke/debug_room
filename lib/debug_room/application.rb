module DebugRoom
  PORT = 20000
  HOST = "127.0.0.1"

  class Application
    def initialize
      check_scr_size
      @main_screen = DebugRoom::MainScreen.new
      @server = DebugRoom::Server.new(@main_screen)
    end

    # 画面サイズが小さいと描画できないのでチェック
    def check_scr_size
      height, width = IO::console_size
      if height < 21 || width < 76
        puts "The size of this console is #{height}x#{width}."
        puts "At least 21x76 console is needed for this application."
        exit 1
      end
    end

    def run
      threads = []
      threads << @main_screen.drawing_thread
      threads << @main_screen.input_thread
      threads << @main_screen.mascot_thread
      threads << watch_cpu_thread
      threads << @server.tcp_thread
      threads.each(&:join)

      @main_screen.close
      @server.close
    rescue Interrupt
      @main_screen.close
      @server.close
    end

    # cpu使用率を監視するスレッド
    def watch_cpu_thread
      Thread.new do
        stat01 = stat_result
        stat02 = stat_result

        until @main_screen.exit
          stat01 = stat02
          sleep 1
          stat02 = stat_result

          @main_screen.mascot.on_busy = stat01.zip(stat02).map do |cpu01, cpu02|
            sub = cpu02.zip(cpu01).map { |a, b| a - b }
            total = sub.inject(:+).to_f
            sub.each_with_object(total).map(&:/)
          end.map { |cpu| cpu[3] < 0.05 }.any?
        end
      end
    end

    # watch_cpu_thread で使われる /proc/stat の情報を返す
    def stat_result
      `cat /proc/stat`.split("\n").select do |line|
        line.match(/^cpu\d+/)
      end.map do |cpu|
        cpu.split[1..4].map { |v| v.to_i }
      end
    end
  end
end
