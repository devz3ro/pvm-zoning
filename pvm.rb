#!/usr/local/bin/ruby
require 'creek'

puts "Enter the workbook file name (Example: pvm.xlsx)"
excel = gets.chomp
workbook = Creek::Book.new "#{excel}"
worksheets = workbook.sheets

host_wwpn_list = []
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

my_array = ["one", "two", "three", "four"]

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

host_wwpn_list.each do |host|
  zone_file.puts "zone name #{platform.upcase}-#{nums}-#{target.upcase}-#{host[2]} vsan #{vsan}"
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
