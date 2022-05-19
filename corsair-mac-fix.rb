#!/usr/bin/ruby
require 'fileutils'

def prompt(answer)
    unless (answer == "Y") || (answer == "N")
        until (answer == "Y") || (answer == "N")
            print "Invalid input, please try again: "
            answer = gets.upcase.strip
        end
    end
end

puts
puts "(Note: sudo password is required, enter it if prompted)"
print "Have you previously attempted to install iCUE and would you like me to clean up? [Delete -> /Applications/Corsair] (Y/N): "
previous_install = gets.upcase.strip
prompt (previous_install)

if previous_install == "Y"
    system "ps aux | grep -i icue | awk '{print $2}' | xargs kill -9"
    system "/usr/bin/sudo rm -rf /Applications/Corsair/"
end

puts

print "Have you previously installed homebrew (http://brew.sh)? (Y/N): "
existing = gets.upcase.strip
prompt(existing)

puts

if existing == "N"
    system "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    puts
end

sleep 1
system "/usr/local/bin/brew install kamilturek/python2/python@2"
sleep 1
puts
system "/usr/local/bin/python2 -m pip install pyobjc-framework-Cocoa"
sleep 1
puts
system "/usr/local/bin/python2 -m pip install PyCocoa"
puts
puts "Creating requred file, it will be located here: #{FileUtils.pwd()}/set-file-icon"
corsair_file = File.open("set-file-icon", "w:UTF-8")
corsair_file.puts "#!/usr/local/bin/python2"
corsair_file.puts
corsair_file.puts "import Cocoa"
corsair_file.puts "import sys"
corsair_file.puts
corsair_file.puts "Cocoa.NSWorkspace.sharedWorkspace().setIcon_forFile_options_(Cocoa.NSImage.alloc().initWithContentsOfFile_(sys.argv[1].decode('utf-8')), sys.argv[2].decode('utf-8'), 0) or sys.exit(\"Unable to set file icon\")"
corsair_file.close
FileUtils.chmod 0755, "#{FileUtils.pwd()}/set-file-icon"

puts
puts "After continuing below, you may start the iCUE Installer."
puts
puts "While it's installing, leave the terminal window open it the background, crtl+c in the terminal window after installation completes."
puts

print "Continue? (Y/N): "
continue = gets.upcase.strip
prompt(continue)

puts
print "Enter your sudo password if prompted -> "

if continue == "Y"
    while true
        system "/usr/bin/sudo /bin/cp -v -f #{FileUtils.pwd()}/set-file-icon /Applications/Corsair/iCUEUninstaller.app/Contents/Scripts/"
        sleep 0.1
    end
end
