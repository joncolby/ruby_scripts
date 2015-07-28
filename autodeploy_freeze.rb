require 'net/http'
require 'net/https'
require 'pstore'

abort("script expects argument:  freeze|unfreeze") if ARGV.empty? || ! %w(freeze unfreeze).include?(ARGV[0])

puts "setting autodeploy production queue to: #{ARGV[0]}"

username='admin'
password='XXXXXX'
pstore_file='autodeploy-cookies.pstore'
cookies = PStore.new(pstore_file)
autodeploy_url='autodeploy.corp.mobile.de'
http = Net::HTTP.new(autodeploy_url, 443)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
login_path = '/autodeploy/j_spring_security_check'

path='/autodeploy/admin/unfreeze'
path='/autodeploy/admin/freeze' if ARGV[0] == 'freeze'


response, data = http.post(login_path,"j_username=#{username}&j_password=#{password}",{'Content-Type' => 'application/x-www-form-urlencoded'})

cookie = response['set-cookie']

cookies.transaction do
  cookies[:autodeploy_login] = cookie
end

autodeploy_cookie = nil
cookies.transaction do
  autodeploy_cookie = cookies[:autodeploy_login] 
end

get_headers = {
  'Cookie' => autodeploy_cookie,
  'Content-Type' => 'application/x-www-form-urlencoded'
}

response = http.get(path,get_headers)

# delete cookie store file
File.delete(pstore_file)

puts "### Response body:"
puts response.body
puts "### Status: #{response.code}"
puts "### Response message: #{response.message}"
puts
puts "### Headers:"
response.each {|key, val| puts key + ' = ' + val}
