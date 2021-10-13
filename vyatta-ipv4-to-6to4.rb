#!/usr/local/bin/ruby
require 'net/http'
require 'resolv'

puts "Enter old IPv4 address or hostname:"
hostname_old = gets.chomp
ipv4_old = Resolv.getaddress("#{hostname_old}").split('.')
uri = URI('https://checkip.amazonaws.com')
ipv4_new = Net::HTTP.get(uri).chomp.split('.')
ipv4_local = Net::HTTP.get(uri).chomp

old_first_octet = ipv4_old[0].to_i.to_s(16)
old_second_octet = ipv4_old[1].to_i.to_s(16)
old_third_octet = ipv4_old[2].to_i.to_s(16)
old_fourth_octet = ipv4_old[3].to_i.to_s(16)

new_first_octet = ipv4_new[0].to_i.to_s(16)
new_second_octet = ipv4_new[1].to_i.to_s(16)
new_third_octet = ipv4_new[2].to_i.to_s(16)
new_fourth_octet = ipv4_new[3].to_i.to_s(16)

puts
puts "delete interfaces ethernet eth6 address 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:1::1/64"
puts "delete interfaces ethernet eth6 ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:1::1/64 autonomous-flag true"
puts "delete interfaces ethernet eth6 ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:1::1/64 on-link-flag true"
puts "delete interfaces ethernet eth6 ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:1::1/64 valid-lifetime 2592000"
puts "delete interfaces ethernet eth6 ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:1::1/64"
puts "delete interfaces ethernet eth6 ipv6 router-advert radvd-options \"RDNSS 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:1::1 {};\""
puts "delete interfaces tunnel tun0 address 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}::/48"
puts
puts "set interfaces ethernet eth6 address 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:1::1/64"
puts "set interfaces ethernet eth6 ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:1::1/64"
puts "set interfaces ethernet eth6 ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:1::1/64 autonomous-flag true"
puts "set interfaces ethernet eth6 ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:1::1/64 on-link-flag true"
puts "set interfaces ethernet eth6 ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:1::1/64 valid-lifetime 2592000"
puts "set interfaces ethernet eth6 ipv6 router-advert radvd-options \"RDNSS 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:1::1 {};\""
puts "set interfaces tunnel tun0 address 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}::/48"
puts "set interfaces tunnel tun0 local-ip #{ipv4_local}"
puts
puts "delete interfaces ethernet eth7 address 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:2::1/64"
puts "delete interfaces ethernet eth7 ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:2::1/64 autonomous-flag true"
puts "delete interfaces ethernet eth7 ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:2::1/64 on-link-flag true"
puts "delete interfaces ethernet eth7 ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:2::1/64 valid-lifetime 2592000"
puts "delete interfaces ethernet eth7 ipv6 router-advert prefix 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:2::1/64"
puts "delete interfaces ethernet eth7 ipv6 router-advert radvd-options \"RDNSS 2002:#{old_first_octet}#{old_second_octet}:#{old_third_octet}#{old_fourth_octet}:2::1 {};\""
puts
puts "set interfaces ethernet eth7 address 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:2::1/64"
puts "set interfaces ethernet eth7 ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:2::1/64"
puts "set interfaces ethernet eth7 ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:2::1/64 autonomous-flag true"
puts "set interfaces ethernet eth7 ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:2::1/64 on-link-flag true"
puts "set interfaces ethernet eth7 ipv6 router-advert prefix 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:2::1/64 valid-lifetime 2592000"
puts "set interfaces ethernet eth7 ipv6 router-advert radvd-options \"RDNSS 2002:#{new_first_octet}#{new_second_octet}:#{new_third_octet}#{new_fourth_octet}:2::1 {};\""