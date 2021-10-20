#!/usr/local/bin/ruby
require 'creek'
require 'net/ssh'
require 'net/ssh/telnet'

def cmd(ssh_exec,command_string)
  input_prompt = true
  output = ''
  ssh_exec.cmd(command_string) do |command_input|
      fixed_input << command_input.gsub(/\e\].*?\a/,"").gsub(/\e\[.*?m/,"").gsub(/\r/,"")
          if fixed_input =~ /(^.*?)\n(.*)$/m
              if input_prompt
                  puts "[SSH]> " + command_string
                  input_prompt = false
              else
                  puts "[SSH]< " + $1
              end
              output = $2
          end
      end
      output.each_line do |last|
          puts "[SSH]< " + last.chomp
      end
  end

puts "Enter the workbook file name (Example: pvm.xlsx)"
excel = gets.chomp
workbook = Creek::Book.new "#{excel}"
worksheets = workbook.sheets

host_wwpn_list = []
zone_member_list = []
svc_target_wwpn_list = {
  "SVCP1" => "500507680c11a766",
  "SVCP2" => "500507680c11a787",
  "SVCP3" => "500507680c11a788",
  "SVCP4" => "500507680c11a789",
  "SVCP5" => "500507680c31a766",
  "SVCP6" => "500507680c31a787",
  "SVCP7" => "500507680c31a788",
  "SVCP8" => "500507680c31a789"
}
nums = 1

puts "Enter the host type (Example: RS)"
platform = gets.chomp
puts "Enter the target device (Example: SVC)"
target = gets.chomp
puts "Enter the vsan (Example: 100)"
vsan = gets.chomp

worksheets.each do |worksheet|
  worksheet.rows.each do |row|
    row_cells = row.values
    unless row_cells.grep(/^c05/).empty?
      host_wwpn_list << row_cells
    end
  end
end

zone_file = File.open("zone_file.txt", "w:UTF-8")
zone_file.puts "configure terminal"

host_wwpn_list.each do |host|
  zone_file.puts "zone name #{platform.upcase}-#{target.upcase}-#{nums}-#{host[2]} vsan #{vsan}"
  zone_member_list << "member #{platform.upcase}-#{target.upcase}-#{nums}-#{host[2]}"
  host[3].split("\n").each do |address|
    zone_file.puts "member pwwn " + address
  end
  if target.upcase == "SVC"
    svc_target_wwpn_list.each do |storage,wwpn|
      zone_file.puts "member pwwn " + wwpn
    end
  end
  nums += 1
end

puts "Enter the customer name (Example: SONJ)"
customer = gets.chomp
puts "Enter the work order number (Example: WO12434)"
work_order = gets.chomp
puts "Enter the start and duration (Example: 0101-8am-48hrs)"
duration = gets.chomp

zone_file.puts
zone_file.puts "zoneset name #{customer.upcase}-#{work_order.upcase}-#{duration.upcase}"
zone_file.puts zone_member_list
zone_file.close
puts

puts "Enter switch ip:"
server = gets.chomp
puts "Enter your (switch) username:"
user = gets.chomp
puts "Enter your (switch) password:"
pass = STDIN.noecho(&:gets).chomp

Net::SSH.start(server, user, :password => pass) do |ssh|
  command_file = File.read("zone_file.txt").split("\n")
  ssh_exec = Net::SSH::Telnet.new("Session" => ssh)
  command_file.each do |command|
    cmd(ssh_exec,"#{command}")
    sleep 0.5
  end
end