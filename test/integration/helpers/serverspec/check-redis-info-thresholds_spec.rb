# frozen_string_literal: true

require 'spec_helper'
require 'shared_spec'

gem_path = '/usr/local/bin'
check_name = 'check-redis-info-thresholds.rb'
check = "#{gem_path}/#{check_name}"

describe 'ruby environment' do
  it_behaves_like 'ruby checks', check
end

# Note: We test with tcp_port because we know this will always return 6379

# tcp_port = 6379, OK because thresholds are not exceeded
describe command("#{check} -P foobared -K tcp_port -w 6380 -c 6381") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(Regexp.new(Regexp.escape('is below defined limits'))) }
end

# tcp_port = 6379, WARNING because WARNING threshold is exceeded
describe command("#{check} -P foobared -K tcp_port -w 6378 -c 6380") do
  its(:exit_status) { should eq 1 }
  its(:stdout) { should match(Regexp.new(Regexp.escape('is above the WARNING limit'))) }
end

# tcp_port = 6379, CRITICAL because CRITICAL threshold is exceeded
describe command("#{check} -P foobared -K tcp_port -w 6377 -c 6378") do
  its(:exit_status) { should eq 2 }
  its(:stdout) { should match(Regexp.new(Regexp.escape('is above the CRITICAL limit'))) }
end
