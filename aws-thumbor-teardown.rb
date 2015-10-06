require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'

REGION = 'us-east-1'

Aws.config.update(region: REGION)
sqs_client = Aws::SQS::Client.new
messages = sqs_client.receive_message(queue_url: ENV['QUEUE'], max_number_of_messages: 1).messages
if messages.empty?
  puts 'No new messages'
else
  messages.each do |message|
    begin
      body = JSON.parse(message.body)
      sns_message = JSON.parse(body["Message"])
      if sns_message["Event"] ==  "autoscaling:EC2_INSTANCE_TERMINATE"
        puts "Termination event"
        # Send 2 nagios commands
        # uri = URI [host, command, image_uri].join('/')
        # response = Net::HTTP.get_response(uri)
        # send knife command
      else
        puts "Not a termniation event"
        sqs_client.delete_message(queue_url: ENV['QUEUE'], receipt_handle: message.receipt_handle)
      end
    rescue JSON::ParserError
      puts "Not an SNS message"
      sqs_client.delete_message(queue_url: ENV['QUEUE'], receipt_handle: message.receipt_handle)
    ensure
      # sqs_client.delete_message(queue_url: ENV['QUEUE'], receipt_handle: message.receipt_handle)
    end
  end
end
