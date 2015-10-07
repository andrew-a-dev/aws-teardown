require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'

def nagios_request(command, host)
  uri = URI.parse(ENV['NAGIOS_URL'])
  uri.query = URI.encode_www_form(cmd_typ: command, cmd_mod: 2, host: host)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  puts "Requesting: #{uri.request_uri}"
  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth ENV['NAGIOS_USER'], ENV['NAGIOS_PASSWORD']
  http.request(request)
end

sqs_client = Aws::SQS::Client.new(region: 'us-east-1')
messages = sqs_client.receive_message(queue_url: ENV['QUEUE'], max_number_of_messages: 1).messages
if messages.empty?
  puts 'No new messages'
else
  messages.each do |message|
    begin
      body = JSON.parse(message.body)
      if body["LifecycleTransition"] == "autoscaling:EC2_INSTANCE_TERMINATING"
        instance = body["EC2InstanceId"]
        host = ENV['AWS_ENV'] == 'staging' ? "thumbor-aws-staging-#{instance}" : "thumbor-aws-#{instance}"
        # Disable notifications
        puts "Problem disabling nagios notificaitons" unless nagios_request('25', host).code == '200'
        # Disable active checks
        puts "Problem disabling nagios checks" unless nagios_request('48', host).code == '200'
        # Delete the node
        system('knife','node','delete', '-y', "#{host}.vpc.voxops.net")
      else
        puts "Not a termniation event"
      end
    rescue JSON::ParserError
      puts "Not an SNS message"
    ensure
      sqs_client.delete_message(queue_url: ENV['QUEUE'], receipt_handle: message.receipt_handle)
    end
  end
end
