#!/usr/local/bin/ruby
require 'creek'
require 'net/ssh'
require 'net/ssh/telnet'

def cmd(ssh_exec,command_string)
  input_prompt = true
  fixed_output = ''
  ssh_exec.cmd(command_string) do |command_input|
    # Not needed for NX-OS: .gsub(/\e\].*?\a/,"") or .gsub(/\e\[.*?m/,"")
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
      puts "[SSH]< " + last.chomp
    end
end

puts
print "Enter the workbook file name (Example - pvm.xlsx): "
excel = gets.chomp
workbook = Creek::Book.new "#{excel}"
worksheets = workbook.sheets

host_wwpn_list = []
zone_member_list = []
hba_port = ['A', 'B'].cycle

svc_target_wwpn_list = {
  "SVCP01" => "500507680c11a766",
  "SVCP02" => "500507680c11a787",
  "SVCP03" => "500507680c11a788",
  "SVCP04" => "500507680c11a789",
  "SVCP05" => "500507680c31a766",
  "SVCP06" => "500507680c31a787",
  "SVCP07" => "500507680c31a788",
  "SVCP08" => "500507680c31a789"
}

sonj_coe_target_wwpn_list = {
  "SONJCOEP01" => "50050768103145a4",
  "SONJCOEP02" => "50050768103545a4",
  "SONJCOEP03" => "50050768103945a4",
  "SONJCOEP04" => "5005076810314755",
  "SONJCOEP05" => "5005076810354755",
  "SONJCOEP06" => "5005076810394755",
  "SONJCOEP07" => "50050768103245a4",
  "SONJCOEP08" => "50050768103a45a4",
  "SONJCOEP09" => "50050768103645a4",
  "SONJCOEP10" => "5005076810324755",
  "SONJCOEP11" => "50050768103a4755",
  "SONJCOEP12" => "5005076810364755"
}

host_num = '001'
target_port_count = 1

puts
print "Enter the host type (Example -> RS): "
platform = gets.chomp
puts
puts "Currently defined targets: (SVC | SONJCOE)"
print "Enter the target device (Example -> MT920): "
target = gets.chomp
puts
print "Enter the vsan (Example -> 100): "
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
  zone_member_list << "member #{platform.upcase}-#{target.upcase}-#{host_num}-#{host[2]}"
  if target.upcase == "SVC"
    hba_num = 0
    host[3].split("\n").each do |address|
      zone_file.puts "zone name #{platform.upcase}-#{target.upcase}-#{host_num}-hba#{hba_num}-#{host[2]} vsan #{vsan}"
      zone_file.puts "member pwwn " + address
      if target_port_count % 2 == 0
        svc_target_wwpn_list.each_slice(4).to_a[1].to_h.each do |svcstorage,svcwwpn|
          zone_file.puts "member pwwn " + svcwwpn
        end
      else
        svc_target_wwpn_list.each_slice(4).to_a[0].to_h.each do |svcstorage,svcwwpn|
          zone_file.puts "member pwwn " + svcwwpn
        end
      end
      hba_num += 1
      target_port_count += 1
    end
  elsif target.upcase == "SONJCOE"
    hba_num = 0
    host[3].split("\n").each do |address|
      zone_file.puts "zone name #{platform.upcase}-#{target.upcase}-#{host_num}-hba#{hba_num}-#{host[2]} vsan #{vsan}"
      zone_file.puts "member pwwn " + address
      if target_port_count % 2 == 0
        sonj_coe_target_wwpn_list.each_slice(6).to_a[1].to_h.each do |coestorage,coewwpn|
          zone_file.puts "member pwwn " + coewwpn
        end
      else
        sonj_coe_target_wwpn_list.each_slice(6).to_a[0].to_h.each do |coestorage,coewwpn|
          zone_file.puts "member pwwn " + coewwpn
        end
      end
      hba_num += 1
      target_port_count += 1
    end
  else
    hba_num = 0
    host[3].split("\n").each do |address|
      zone_file.puts "zone name #{platform.upcase}-#{target.upcase}-#{host_num}-hba#{hba_num}-#{host[2]} vsan #{vsan}"
      zone_file.puts "member pwwn " + address
      hba_num += 1
    end
  end
  host_num = host_num.next
end

puts
print "Enter the customer name (Example -> SONJ): "
customer = gets.chomp
puts
print "Enter the work order number (Example -> WO12434): "
work_order = gets.chomp
puts
print "Enter the start and duration (Example -> 0101-8am-48hrs): "
duration = gets.chomp

zone_file.puts
zone_file.puts "zoneset name #{customer.upcase}-#{work_order.upcase}-#{duration.upcase} vsan #{vsan}"
zone_file.puts zone_member_list
zone_file.puts "zoneset activate name #{customer.upcase}-#{work_order.upcase}-#{duration.upcase} vsan #{vsan}"
zone_file.puts "zone commit vsan #{vsan}"
zone_file.close

puts
print "Enter switch ip: "
server = gets.chomp
puts
print "Enter your (switch) username: "
user = gets.chomp
puts
print "Enter your (switch) password: "
pass = STDIN.noecho(&:gets).chomp
puts

Net::SSH.start(server, user, :password => pass) do |ssh|
  command_file = File.read("zone_file.txt").split("\n")
  ssh_exec = Net::SSH::Telnet.new("Session" => ssh)
  command_file.each do |command|
    cmd(ssh_exec,"#{command}")
    sleep 1
  end
end