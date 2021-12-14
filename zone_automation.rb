#!/usr/local/bin/ruby
require 'creek'
require 'net/ssh'
require 'net/ssh/telnet'

def cmd(ssh_exec,command_string)
  input_prompt = true
  fixed_output = ''
  ssh_exec.cmd(command_string) do |command_input|
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

def parsesheets(grep)
  @worksheets.each do |worksheet|
    worksheet.rows.each do |row|
      row_cells = row.values
      unless row_cells.grep(/#{grep}/).empty?
        @host_wwpn_list.push(row_cells)
      end
    end
  end
end

def make_zone(target_wwpn_list, slice, host, field, roundr, hf1, hf2, cell)
  unless host[field].nil?
    hba_num = 0
    host[field].split("\n").each do |address|
      @zone_member_list.push("member #{@platform.upcase}-#{@target.upcase}-#{@host_num}-#{hf1}-#{hf2}")
      @zone_file.puts "zone name #{@platform.upcase}-#{@target.upcase}-#{@host_num}-#{hf1}-#{hf2} vsan #{@vsan}"
      if @platform_input == "pvm"
        @zone_file.puts "member pwwn " + address
      else
        @zone_file.puts "member pwwn " + host[cell].gsub(/:/,"")
      end
      unless roundr.nil?
        if @target_port_count % 2 == 0
          target_wwpn_list.each_slice(slice).to_a[1].to_h.each do |target,wwpn|
            @zone_file.puts "member pwwn " + wwpn
          end
        else
          target_wwpn_list.each_slice(slice).to_a[0].to_h.each do |target,wwpn|
            @zone_file.puts "member pwwn " + wwpn
          end
        end
        @target_port_count += 1
      end
      hba_num += 1
    end
  end
end

svc_target_wwpn_list = {
  SVCP01: "500507680c11a766",
  SVCP02: "500507680c11a787",
  SVCP03: "500507680c11a788",
  SVCP04: "500507680c11a789",
  SVCP05: "500507680c31a766",
  SVCP06: "500507680c31a787",
  SVCP07: "500507680c31a788",
  SVCP08: "500507680c31a789"
}

sonj_coe_target_wwpn_list = {
  SONJCOEP01: "50050768103145a4",
  SONJCOEP02: "50050768103545a4",
  SONJCOEP03: "50050768103945a4",
  SONJCOEP04: "5005076810314755",
  SONJCOEP05: "5005076810354755",
  SONJCOEP06: "5005076810394755",
  SONJCOEP07: "50050768103245a4",
  SONJCOEP08: "50050768103a45a4",
  SONJCOEP09: "50050768103645a4",
  SONJCOEP10: "5005076810324755",
  SONJCOEP11: "50050768103a4755",
  SONJCOEP12: "5005076810364755"
}

american_greetings_wwpn_list = {
  AMERGP01: "524a937da6752100",
  AMERGP02: "524a937da6752103",
  AMERGP03: "524a937da6752110",
  AMERGP04: "524a937da6752113"
}

puts
puts "Valid platform choices are: (pvm | intel)"
print "Please enter your platform: "

@platform_input = gets.strip

unless (@platform_input == "pvm") || (@platform_input == "intel")
    until (@platform_input == "pvm") || (@platform_input == "intel")
        print "invalid input, please try again: "
        @platform_input = gets.strip
    end
end

puts
print "Enter the workbook file name (Example - sonj.xlsx): "
excel = gets.strip
workbook = Creek::Book.new "#{excel}"
@worksheets = workbook.sheets

puts
print "Enter the host type (Example -> RS or CS): "
@platform = gets.strip
puts
puts "Currently defined targets: (SVC | SONJCOE | AMERGCOE)"
print "Enter the target device (Example -> MT920): "
@target = gets.strip
puts
print "Enter the vsan (Example -> 100): "
@vsan = gets.strip

pvmf = [3, 7, 11, 15, 19]
@host_wwpn_list = []
@host_num = '001'
@target_port_count = 1
@zone_member_list = []
@zone_file = File.open("zone_file.txt", "w:UTF-8")
@zone_file.puts "configure terminal"

if @platform_input == "pvm"
  parsesheets("^c05")
  pvmf.each do |field|
    @host_wwpn_list.each do |host|
      case @target.upcase
      when "SVC"
        make_zone(svc_target_wwpn_list, svc_target_wwpn_list.length / 2, host, field, true, "hba#{@hba_num}", "#{host[field - 1]}", nil)
      when "SONJCOE"
        make_zone(sonj_coe_target_wwpn_list, sonj_coe_target_wwpn_list.length / 2, host, field, true, "hba#{@hba_num}", "#{host[field - 1]}", nil)
      when "AMERGCOE"
        make_zone(american_greetings_wwpn_list, american_greetings_wwpn_list.length / 2, host, field, true, "hba#{@hba_num}", "#{host[field - 1]}", nil)
      else
        make_zone(nil, nil, host, field, nil, "hba#{@hba_num}", "#{host[field - 1]}", nil)
      end
      @host_num = @host_num.next
    end
  end
end

if @platform_input == "intel"
  parsesheets("vHBA")
  @host_wwpn_list.each do |host|
    case @target.upcase
    when "SVC"
      make_zone(svc_target_wwpn_list, svc_target_wwpn_list.length / 2, host, 5, true, "#{host[3]}", "#{host[1]}", 5)
    when "SONJCOE"
      make_zone(sonj_coe_target_wwpn_list, sonj_coe_target_wwpn_list.length / 2, host, 5, true, "#{host[3]}", "#{host[1]}", 5)
    when "AMERGCOE"
      make_zone(american_greetings_wwpn_list, american_greetings_wwpn_list.length / 2, host, 5, true, "#{host[3]}", "#{host[1]}", 5)
    else
      make_zone(nil, nil, host, 5, nil, "hba#{@hba_num}", "#{host[field - 1]}", nil)
    end
    @host_num = @host_num.next
  end
end

puts
print "Enter the customer name (Example -> SONJ): "
customer = gets.strip
puts
print "Enter the work order number (Example -> WO12434): "
work_order = gets.strip
puts
print "Enter the start and duration (Example -> 0101-8am-48hrs): "
duration = gets.strip

@zone_file.puts
@zone_file.puts "zoneset name #{customer.upcase}-#{work_order.upcase}-#{duration.upcase} vsan #{@vsan}"
@zone_file.puts @zone_member_list
@zone_file.puts "zoneset activate name #{customer.upcase}-#{work_order.upcase}-#{duration.upcase} vsan #{@vsan}"
@zone_file.puts "zone commit vsan #{@vsan}"
@zone_file.close

puts
print "Enter switch ip (default = 172.23.79.11): "
server = gets.strip
puts
print "Enter your (switch) username: "
user = gets.strip
puts
print "Enter your (switch) password: "
pass = STDIN.noecho(&:gets).chomp
puts

Net::SSH.start(server, user, :password => pass) do |ssh|
  command_file = File.read("zone_file.txt").split("\n")
  ssh_exec = Net::SSH::Telnet.new("Session" => ssh)
  command_file.each do |command|
    cmd(ssh_exec,"#{command}")
    sleep 0.2
  end
end
