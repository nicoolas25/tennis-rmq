require "bunny"
require "json"
require "open-uri"

module RabbitHelpers
  def client
    @client ||= Bunny.new.tap(&:start)
  end

  def channel
    @channel ||= client.create_channel
  end

  def queue_exists?(klass)
    client.queue_exists?(queue_name(klass))
  end

  def pop(klass)
    _, _, payload = channel.queue(queue_name(klass), durable: true).pop
    payload
  end

  def remove_queues(job_classes)
    job_classes.each do |klass|
      channel.queue(queue_name(klass), durable: true).delete
    end
  end

  private

  def queue_name(klass)
    name = klass.name.gsub("::", "-").downcase
    "tennis-test:queue:#{name}"
  end
end
