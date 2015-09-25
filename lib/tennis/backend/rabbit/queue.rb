require "thread"

module Tennis::Backend
  class RabbitQueue
    def initialize
      @mutex = Mutex.new
      @queue = []
      @received = ConditionVariable.new
    end

    def <<(x)
      @mutex.synchronize do
        @queue << x
        @received.signal
      end
    end

    def pop(timeout = nil)
      @mutex.synchronize do
        @received.wait(@mutex, timeout) if @queue.empty?
        @queue.shift
      end
    end
  end
end
