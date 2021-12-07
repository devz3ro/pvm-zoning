#!/usr/local/bin/ruby
require 'net/ssh'
require 'net/ssh/telnet'
require 'net/http'
require 'resolv'
require 'fileutils'

def cmd(ssh_exec,command_string)
    input_prompt = true
    fixed_output = ''
    ssh_exec.cmd(command_string) do |command_input|
      # Not needed for Vyatta: .gsub(/\e\].*?\a/,"") or .gsub(/\e\[.*?m/,"")
      fixed_output = command_input.gsub(/\r/,"")
        if fixed_output =~ /(^.*?)\n(.*)$/m
          if input_prompt
            puts "[SSH]> " + command_string
            input_prompt = false
          else
            puts "[SSH]< " + $1
          end
          fixed_output = $2
        end
      end
      fixed_output.each_line do |last|
        puts "[SSH]< " + last
      end
  end

vyatta_file = File.open("vyatta_file.txt", "w:UTF-8")
vyatta_file.puts "configure"
puts
print "Enter old IPv4 address or hostname: "
hostname_old = gets.strip
ipv4_old = Resolv.getaddress("#{hostname_old}").split('.')
uri = URI('https://checkip.amazonaws.com')
ipv4_new = Net::HTTP.get(uri).strip.split('.')
ipv4_local = Net::HTTP.get(uri).strip

old_first_octet = ipv4_old[0].to_i.to_s(16)
old_second_octet = ipv4_old[1].to_i.to_s(16)
old_third_octet = ipv4_old[2].to_i.to_s(16)
old_fourth_octet = ipv4_old[3].to_i.to_s(16)

new_first_octet = ipv4_new[0].to_i.to_s(16)
new_second_octet = ipv4_new[1].to_i.to_s(16)
new_third_octet = ipv4_new[2].to_i.to_s(16)
new_fourth_octet = ipv4_new[3].to_i.to_s(16)

print "Please enter your ethX device(s) separated by spaces: "
interfaces = gets.strip
ethX = interfaces.split(" ")
iface_num = 1

ethX.each do |iface|
  vyatta_file.puts "delete interfaces ethernet #{iface} address 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:#{iface_num}::1/64"
  vyatta_file.puts "delete interfaces ethernet #{iface} ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:#{iface_num}::1/64 autonomous-flag true"
  vyatta_file.puts "delete interfaces ethernet #{iface} ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:#{iface_num}::1/64 on-link-flag true"
  vyatta_file.puts "delete interfaces ethernet #{iface} ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:#{iface_num}::1/64 valid-lifetime 2592000"
  vyatta_file.puts "delete interfaces ethernet #{iface} ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:#{iface_num}::1/64"
  vyatta_file.puts "delete interfaces ethernet #{iface} ipv6 router-advert radvd-options \"RDNSS 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:#{iface_num}::1 {};\""
  vyatta_file.puts "delete interfaces tunnel tun0 address 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}::/48"
  vyatta_file.puts
  vyatta_file.puts "set interfaces ethernet #{iface} address 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:#{iface_num}::1/64"
  vyatta_file.puts "set interfaces ethernet #{iface} ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:#{iface_num}::1/64"
  vyatta_file.puts "set interfaces ethernet #{iface} ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:#{iface_num}::1/64 autonomous-flag true"
  vyatta_file.puts "set interfaces ethernet #{iface} ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:#{iface_num}::1/64 on-link-flag true"
  vyatta_file.puts "set interfaces ethernet #{iface} ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:#{iface_num}::1/64 valid-lifetime 2592000"
  vyatta_file.puts "set interfaces ethernet #{iface} ipv6 router-advert radvd-options \"RDNSS 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:#{iface_num}::1 {};\""
  vyatta_file.puts
  iface_num += 1
end

vyatta_file.puts "set interfaces tunnel tun0 address 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}::/48"
vyatta_file.puts "set interfaces tunnel tun0 local-ip #{ipv4_local}"
vyatta_file.puts "set interfaces tunnel tun0 remote-ip 192.88.99.1"
vyatta_file.puts
vyatta_file.puts "commit"
vyatta_file.puts "save"
vyatta_file.puts "exit"
vyatta_file.puts "exit"
vyatta_file.close

puts "Please review the vyatta_file.txt created in the following location: #{FileUtils.pwd()}"
print "Continue? (Y/N): "
answer = gets.upcase.strip
if answer == "Y"
  puts "Continuing..."
else
  puts "Terminating..."
  exit
end

puts
print "Enter router ip: "
server = gets.strip
puts
print "Enter your (router) username: "
user = gets.strip
puts
print "Enter your (router) password: "
pass = STDIN.noecho(&:gets).strip
puts

Net::SSH.start(server, user, :password => pass) do |ssh|
    command_file = File.read("vyatta_file.txt").split("\n")
    ssh_exec = Net::SSH::Telnet.new("Session" => ssh)
    command_file.each do |command|
      cmd(ssh_exec,"#{command}")
      sleep 1
    end
  end
