#!/usr/bin/ruby

begin
  require 'sqlite3'
rescue LoadError
  puts "The 'sqlite3' gem is not installed. Installing..."
  system('gem install sqlite3')
  Gem.clear_paths
  require 'sqlite3'
end

db_file = '/var/lib/emby/data/activitylog.db'
query = 'DELETE FROM ActivityLog WHERE LogSeverity = ?'
db = SQLite3::Database.new(db_file)

if File.exist?(db_file)
  error_entries = db.execute('SELECT * FROM ActivityLog WHERE LogSeverity = ?', 'Error')

  if error_entries.any?
    timestamp = Time.now.strftime('%m/%d/%Y %I:%M %p')

    File.open('emby_clearactivityerror.log', 'a') do |log_file|
      log_file.puts("Error(s) found! Timestamp of execution: #{timestamp}")

      error_entries.each do |entry|
        log_timestamp = Time.at(entry[7] / 1000).strftime('%m/%d/%Y %I:%M %p')
        log_file.puts("LogMessage: #{entry[1]}, LogTimeStamp: #{log_timestamp}, LogIP: #{entry[3]}")
      end
    end

    db.execute(query, 'Error')

    if db.changes > 0
      puts "Deleted #{db.changes} error entries from #{db_file}."
    else
      puts "Failed to delete error entries from #{db_file}."
    end
  else
    puts "No error entries found."
  end

  db.close
else
  puts "Database file #{db_file} does not exist."
end
