#!/usr/bin/env ruby
require 'optparse'

class DeviceScan

  def initialize(config)
    @cfg = {
      :net_prefix => '192.168.',
      :net_start => '0',
      :net_stop => '254',
      :my_ip => '13',
      :my_mask => '/24',
      :device => 'eth0'
    }.merge config

    create_range(
      @cfg[:net_prefix],
      @cfg[:net_start],
      @cfg[:net_stop]
    )
  end

  def debug(msg)
    #puts msg
  end

  def create_range(prefix, start, stop)
    @networks = []
    start = start.to_i
    count = stop.to_i - start.to_i + 1
    count.times do |idx|
      @networks << prefix + (start + idx).to_s + '.'
    end
  end

  def network_up(my_ip)
    debug "Using #{my_ip}"
    `ip a add #{my_ip} dev #{@cfg[:device]}`
  end

  def network_down(my_ip)
    debug "Dropping #{my_ip}"
    `ip a del #{my_ip} dev #{@cfg[:device]}`
  end

  def scan_network(network)
    debug "Scanning #{network}"
    res = `nmap -sn -PR -n #{network} | grep "scan report"`
    res.split("\n").map { |row| row.split(' ')[-1] }
  end

  def print_scan(results, my_ip)
    results = results.find_all { |ip| ip != my_ip }
    puts "Found: #{results}                          \n" unless results.empty?
  end

  def time_elapsed
    Time.now - @_time_start
  end

  def time_estim
    return 0 if @_count_done == 0
    remain = @networks.length - @_count_done
    per_net = time_elapsed() / @_count_done
    return remain * per_net
  end

  def fmt_time(time)
    return "?" if time == 0
    return "<1s" if time < 1

    hours = (time / 3600).to_i
    time -= hours * 3600

    minutes = (time / 60).to_i
    seconds = time - (minutes * 60)

    seconds = seconds.to_i # trim to seconds

    if hours != 0
      return "#{hours}h#{minutes}m#{seconds}s"
    elsif minutes != 0
      return "#{minutes}m#{seconds}s"
    end
    return "#{seconds}s"
  end

  def run
    puts "Using device #{@cfg[:device]}."
    @_time_start = Time.now
    @_count_done = 0
    @networks.each do |net|
      print "== #{net}, Run:#{fmt_time(time_elapsed)} Est:#{fmt_time(time_estim)} ==\r"
      ip = "#{net}#{@cfg[:my_ip]}"
      ip_mask = "#{ip}#{@cfg[:my_mask]}"

      begin
        network_up(ip_mask)
        print_scan( scan_network(net+'0/24'), ip )
        network_down(ip_mask)
      rescue Interrupt
        puts "\nInterrupted - clean and quit ...\n"
        network_down(ip_mask)
        return
      end

      @_count_done += 1
    end
    puts "== DONE after #{fmt_time(time_elapsed)} ==               "
  end
end

def check_root
  unless Process::UID.eid == 0
    puts "Sorry, this has to be run by root."
    puts ""
    puts "This script needs to switch ip addresses and"
    puts "invoke nmap for broadcast ping-scans, which"
    puts "cannot be achieved by regular user."
    false
  end
  true
end

def get_config
  options = {}
  #OptionParser
  options
end

exit unless check_root
scan = DeviceScan.new( get_config() )
scan.run()

