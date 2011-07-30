require "rubygems"
require "bundler/setup"
require "mysql2"
require "mongo"

MYSQL_SETTINGS = {
  host:     "127.0.0.1",
  username: "root",
  password: "",
  database: "myapp_production",
  encoding: "utf8"
}

MONGO_SETTINGS = {
  schema:   "myapp_production"
}

mysql_client = Mysql2::Client.new(MYSQL_SETTINGS)
mongo_client = Mongo::Connection.new.db(MONGO_SETTINGS[:schema])

if MONGO_SETTINGS.has_key?(:username) && MONGO_SETTINGS.has_key?(:password)
  raise SystemExit, "Cannot connect to mongo, provided keys are not valid" unless mongo_client.authenticate(MONGO_SETTINGS[:username], MONGO_SETTINGS[:password])
end

puts "Migrating from: #{MYSQL_SETTINGS[:database]}"

mysql_query_string = "select * from information_schema.tables where table_schema='#{MYSQL_SETTINGS[:database]}'"
mysql_client.query(mysql_query_string).each do |row|
  current_table = row[:TABLE_NAME]
  puts "Working on: #{row[:TABLE_NAME]}"
  inner_qs = "select * from #{current_table}"

  current_collection = mongo_client.collection(current_table)
  mysql_client.query(inner_qs).each do |result_row|
    current_collection.insert(result_row)
  end
end