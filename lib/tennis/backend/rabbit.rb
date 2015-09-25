require "bunny"
require "securerandom"

require "tennis"
require "tennis/backend/abstract"
require "tennis/backend/serializer"
require "tennis/backend/task"

require_relative "rabbit/queue"

module Tennis
  module Backend
    class Rabbit < Abstract

      def initialize(logger:, url:, namespace: "tennis")
        super(logger: logger)
        @rabbit_url = url
        @rabbit_namespace = namespace
        @payload_queue = RabbitQueue.new
        @job_classes = nil
        @setup = false
      end

      # Delayed jobs are not yet supported with Rabbit backend
      def enqueue(job:, method:, args:, delay: nil)
        queue(job.class)
        meta = { "enqueued_at" => Time.now.to_i }
        task = Task.new(self, generate_task_id, job, method, args, meta)
        exchange.publish(serialize(task), routing_key: routing_key(job.class))
      end

      def receive(job_classes:, timeout: 1.0)
        setup(job_classes)
        payload = @payload_queue.pop(timeout)
        payload && deserialize_task(*payload)
      end

      def ack(task)
        delivery_info = task.meta["_backend"]["delivery_info"]
        channel.acknowledge(delivery_info.delivery_tag, false)
      end

      def requeue(task)
        delivery_info = task.meta["_backend"]["delivery_info"]
        channel.reject(delivery_info.delivery_tag, true)
      end

      # Reset the backend:
      # - stop getting messages from the queues
      # - requeue unacked messages
      def reset
        return unless @setup
        @consumers.each(&:cancel)
        @job_classes = nil
        @setup = false
      end

      private

      def setup(job_classes)
        return if @job_classes == job_classes
        raise "The Rabbit backend can't dynamically update its job_classes" if @setup
        @job_classes = job_classes
        @consumers = job_classes.map { |klass| subscribe(klass) }
        @setup = true
      end

      def subscribe(klass)
        queue(klass).subscribe(manual_ack: true) do |delivery_info, properties, payload|
          @payload_queue << [delivery_info, properties, payload]
        end
      end

      def serialize(task)
        filtered_meta = task.meta.dup
        filtered_meta.delete("_backend")
        Serializer.new.dump({
          "id"     => task.task_id,
          "job"    => task.job,
          "method" => task.method,
          "args"   => task.args,
          "meta"   => filtered_meta,
        })
      end

      def deserialize_task(delivery_info, properties, serialized_task)
        hash = Serializer.new.load(serialized_task)
        hash["meta"].merge!("_backend" => {
          "delivery_info" => delivery_info,
          "properties" => properties,
        })
        Task.new(self, hash["id"], hash["job"], hash["method"], hash["args"], hash["meta"])
      end

      def generate_task_id
        SecureRandom.hex(10)
      end

      def queue(klass)
        @queue ||= {}
        @queue[klass] ||=
          channel.queue(queue_name(klass), durable: true).tap do |q|
            q.bind(exchange, routing_key: routing_key(klass))
          end
      end

      def queue_name(klass)
        @queue_name ||= {}
        @queue_name[klass] ||= "%{namespace}:queue:%{klass_name}" % {
          namespace: @rabbit_namespace,
          klass_name: routing_key(klass),
        }
      end

      def routing_key(klass)
        @routing_key ||= {}
        @routing_key[klass] ||= klass.name.gsub("::", "-").downcase
      end

      def exchange
        @echange ||= channel.topic(@rabbit_namespace, durable: true)
      end

      def channel
        @channel ||= client.create_channel.tap do |chan|
          chan.prefetch(10)
        end
      end

      def client
        @client ||= ::Bunny.new(@rabbit_url).tap(&:start)
      end

    end
  end
end
