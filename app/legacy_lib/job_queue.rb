# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
module JobQueue
  def self.queue(klass, *args)
    Delayed::Job.enqueue klass.new(*args)
  end
end