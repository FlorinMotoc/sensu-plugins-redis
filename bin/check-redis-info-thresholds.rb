#!/usr/bin/env ruby
#
#   check-redis-info-thresholds.rb
#
# DESCRIPTION:
#   This plugin checks warning and critical values of variables from redis INFO http://redis.io/commands/INFO
#   Use this with variables that return numeric values (ex: evicted_keys, expired_keys, connected_clients, etc)
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: redis
#
# USAGE:
#   check-redis-info-thresholds.rb -K REDIS_INFO_KEY -w COUNT -c COUNT
#   Example: check-redis-info-thresholds.rb -K evicted_keys -w 1 -c 1000
#
# NOTES:
#   Inspired by check-redis-info.rb and check-redis-connections-available.rb
#
# LICENSE:
#   Copyright Florin Motoc <dev@mflorin.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'redis'
require_relative '../lib/redis_client_options'

class RedisInfoThresholdsCheck < Sensu::Plugin::Check::CLI
  include RedisClientOptions

  option :redis_info_key,
         short: '-K VALUE',
         long: '--redis-info-key KEY',
         description: 'Redis info key to monitor',
         required: true

  option :warning,
         short: '-w COUNT',
         long: '--warning COUNT',
         description: "COUNT warning threshold for number of chosen key's value",
         proc: proc(&:to_i),
         required: true

  option :critical,
         short: '-c COUNT',
         long: '--critical COUNT',
         description: "COUNT critical threshold for number of chosen key's value",
         proc: proc(&:to_i),
         required: true

  def run
    redis = Redis.new(default_redis_options)

    critical_value = config[:critical]
    warning_value = config[:warning]

    redis_info_key = config[:redis_info_key]
    redis_info_key_value = redis.info.fetch(redis_info_key.to_s)

    if redis_info_key_value >= critical_value
      critical "Redis running on #{config[:host]}:#{config[:port]} is above the CRITICAL limit: #{redis_info_key_value} >= #{critical_value}"
    elsif redis_info_key_value >= warning_value
      warning "Redis running on #{config[:host]}:#{config[:port]} is above the WARNING limit: #{redis_info_key_value} >= #{warning_value}"
    else
      ok "Redis running on #{config[:host]}:#{config[:port]} is below defined limits: #{redis_info_key_value} < #{warning_value}"
    end

  rescue StandardError
    send(config[:conn_failure_status], "Could not connect to Redis server on #{redis_endpoint}")
  end
end
