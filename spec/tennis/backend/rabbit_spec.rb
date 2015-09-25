require "tennis/backend/rabbit"

require "support/rabbit_helpers"
require "support/my_job"

RSpec.describe Tennis::Backend::Rabbit do
  include RabbitHelpers

  before { remove_queues [MyJob] }

  describe "#enqueue" do
    subject(:enqueue) { instance.enqueue(job: job, method: method, args: args) }

    it "creates a queue 'tennis-test:queue:myjob' into rabbitmq" do
      expect { enqueue }.to change { queue_exists?(MyJob) }.to(true)
    end

    it "adds the task into the queue" do
      enqueue
      expect(pop(MyJob)).to_not be_nil
    end
  end

  describe "#receive" do
    subject(:receive) { instance.receive(job_classes: [MyJob], timeout: timeout) }

    context "when no job are available" do
      it { is_expected.to be_nil }
    end

    context "when a job had been enqueued" do
      # Enqueue a job
      before { instance.enqueue(job: job, method: method, args: args) ; sleep 0 }

      it { is_expected.to be_a Tennis::Backend::Task }

      context "with a bigger timeout" do
        let(:timeout) { 100.0 }

        it "returns the task instantly" do
          expect(receive).to be_a Tennis::Backend::Task
        end
      end

      describe "the returned task" do
        subject(:task) { receive }

        it "matches the given job, method and arguments" do
          expect(task.job).to be_a MyJob
          expect(task.method).to eq "sum"
          expect(task.args).to eq [1, 2, 3]
        end

        it "adds meta information: 'enqueued_at'" do
          expect(task.meta).to include "enqueued_at"
        end

        it "adds meta information: '_backend'" do
          expect(task.meta).to include "_backend"
        end
      end
    end
  end

  describe "#ack" do
    subject(:ack) { instance.ack(task) }

    before do
      # Enqueue a job and retrieve the associated task
      instance.enqueue(job: job, method: method, args: args)
      task
    end

    it "call ack on the channel with the right delivery_tag" do
      expect_any_instance_of(Bunny::Channel)
        .to receive(:acknowledge)
        .with(task.meta["_backend"]["delivery_info"].delivery_tag, false)
        .and_call_original
      ack
    end

    let(:task) { instance.receive(job_classes: [MyJob]) }
  end

  describe "#requeue" do
    subject(:requeue) { instance.requeue(task) }

    before do
      # Enqueue a job and retrieve the associated task
      instance.enqueue(job: job, method: method, args: args)
      task

      # Reset the backend (stop getting messages from the queues)
      instance.reset
    end

    it "adds back the task into the queue" do
      requeue
      expect(pop(MyJob)).to_not be_nil
    end

    describe "the task after being requeued" do
      subject(:requeued_task) { instance.receive(job_classes: [MyJob]) }

      # Requeue the task
      before { requeue }

      it "adds meta information: '_backend'" do
        expect(requeued_task.meta).to include "_backend"
        expect(requeued_task.meta["_backend"]["delivery_info"]).to be_redelivered
      end
    end

    let(:task) { instance.receive(job_classes: [MyJob]) }
  end

  let(:job) { MyJob.new }
  let(:method) { "sum" }
  let(:args) { [1, 2, 3] }
  let(:timeout) { 0.0 }
  let(:instance) do
    described_class.new(
      logger: nil,
      url: "amqp://guest:guest@localhost:5672",
      namespace: "tennis-test")
  end

end
