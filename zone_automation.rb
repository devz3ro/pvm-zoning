#!/usr/local/bin/ruby
require 'json'
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
      puts "[SSH]< " + last.strip
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
      unless hf1.nil?
        @zone_member_list.push("member #{@platform.upcase}-#{@target.upcase}-#{@host_num}-#{hf1}-#{hf2}")
        @zone_file.puts "zone name #{@platform.upcase}-#{@target.upcase}-#{@host_num}-#{hf1}-#{hf2} vsan #{@vsan}"
      else
        @zone_member_list.push("member #{@platform.upcase}-#{@target.upcase}-#{@host_num}-hba#{hba_num}-#{hf2}")
        @zone_file.puts "zone name #{@platform.upcase}-#{@target.upcase}-#{@host_num}-hba#{hba_num}-#{hf2} vsan #{@vsan}"
      end
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

def answer(input, ans1, ans2)
  unless (input == ans1) || (input == ans2)
    until (input == ans1) || (input == ans2)
      print "invalid input, please try again: "
      input = gets.strip
    end
  end
end

puts
puts "Valid platform choices are: (pvm | intel)"
print "Please enter your platform: "

@platform_input = gets.strip
answer(@platform_input, "pvm", "intel")

puts
print "Enter the workbook file name (Example - sonj.xlsx): "
excel = gets.strip
workbook = Creek::Book.new "#{excel}"
@worksheets = workbook.sheets

wwpn_file = File.read("config.json")
@wwpn_data = JSON.parse(wwpn_file)

@wwpn_data.sort_by! { |name| 
	name["wwpn_name"]
}

puts
print "Enter the host type (Example -> RS or CS): "
@platform = gets.strip
puts
puts "Currently defined targets:"
@wwpn_data.each { |wwpn_print|
	puts wwpn_print["wwpn_id"] + " = " + wwpn_print["short_name"]
}
puts
print "Enter the target device: "
@target = gets.strip
tgt_wwpn_list = {}
name_wwpn_list = []
@wwpn_data.each do |group|
  name_wwpn_list.push(group["short_name"])
  if (group["wwpn_id"] == "#{@target}") || (group["short_name"] == "#{@target}")
    tgt_wwpn_list = group["ports"]
    @target = group["short_name"]
  end
end

puts
print "Enter the vsan (Example -> 100): "
@vsan = gets.strip

pvmf = [3, 7, 11, 15, 19]
@host_wwpn_list = []
intelarray = []
@host_num = '001'
@target_port_count = 1
@zone_member_list = []
@zone_file = File.open("zone_file.txt", "w:UTF-8")
@zone_file.puts "configure terminal"

if @platform_input == "pvm"
  parsesheets("^c05")
  pvmf.each do |field|
    @host_wwpn_list.each do |host|
      if name_wwpn_list.include?(@target.upcase)
        make_zone(tgt_wwpn_list, tgt_wwpn_list.length / 2, host, field, true, nil, "#{host[field - 1]}", nil)
      else
        make_zone(nil, nil, host, field, nil, nil, "#{host[field - 1]}", nil)
      end
      @host_num = @host_num.next
    end
  end
end

if @platform_input == "intel"
  parsesheets("vHBA")
  @host_wwpn_list.each_with_index do |host, index|
    intelarray.push(host[1])
    unless host[1] == intelarray[index - 1]
      @host_num = @host_num.next
    end
    if name_wwpn_list.include?(@target.upcase)
      make_zone(tgt_wwpn_list, tgt_wwpn_list.length / 2, host, 5, true, "#{host[3]}", "#{host[1]}", 5)
    else
      make_zone(nil, nil, host, 5, nil, "#{host[3]}", "#{host[1]}", 5)
    end
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
puts "zone_file.txt created in #{FileUtils.pwd()}, please review it for accuracy."
puts
print "Enter switch ip (default = 172.23.79.11): "
server = gets.strip
puts
print "Enter your (switch) username: "
user = gets.strip
puts
print "Enter your (switch) password: "
pass = STDIN.noecho(&:gets).strip
puts

Net::SSH.start(server, user, :password => pass) do |ssh|
  command_file = File.read("zone_file.txt").split("\n")
  ssh_exec = Net::SSH::Telnet.new("Session" => ssh)
  command_file.each do |command|
    cmd(ssh_exec,"#{command}")
    sleep 0.5
  end
end
