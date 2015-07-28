require 'net/http'
require 'net/https'
require 'pstore'

username='admin'
password='XXXXX'
pstore_file='autodeploy-cookies.pstore'
cookies = PStore.new(pstore_file)
autodeploy_url='autodeploy.corp.mobile.de'
http = Net::HTTP.new(autodeploy_url, 443)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
#path = '/autodeploy/login/auth'
path = '/autodeploy/j_spring_security_check'
freeze_path='/autodeploy/admin/freeze'
unfreeze_path='/autodeploy/admin/unfreeze'

response, data = http.post(path,"j_username=#{username}&j_password=#{password}",{'Content-Type' => 'application/x-www-form-urlencoded'})

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

response = http.get(unfreeze_path,get_headers)

# delete cookie store file
File.delete(pstore_file)

puts "### Response body:"
puts response.body
puts "### Status: #{response.code}"
puts "### Response message: #{response.message}"
puts
puts "### Headers:"
response.each {|key, val| puts key + ' = ' + val}
