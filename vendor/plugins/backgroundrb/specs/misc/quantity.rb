# run with server:
# ./script/backgroundrb run -- -w ./specs/data/server/workers
#
# we use this script to check issues with having many slaves active
# simultaneously.
# 
# we see occasional failed worker creation attempts right now with this
#
require 'drb'

max = ARGV[0]
unless max
  max = 100
end

DRb.start_service('druby://localhost:0')
m = DRbObject.new(nil, "druby://localhost:2000")

job_keys = (1..100).map { |f| ("job" + f.to_s).to_sym }

job_keys.each do |k|
  m.new_worker :class => :simple_worker, :job_key => k
  p m.worker(k).simple_work_with_logging
end

job_keys.each do |k|
  p m.worker(k).simple_work_with_logging
  m.worker(k).delete
end

