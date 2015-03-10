require 'open-uri'
require 'csv'
require File.expand_path('../lib/contractually', __FILE__)

@server = ARGV[0]
@api_token = ARGV[1]
@template_id = ARGV[2]
@filename = ARGV[3]
@invite_user = ARGV[4]

CSV.foreach(@filename, headers: true) do |row|
  api = Contractually::Api.new(@server, @api_token)

  contract = Contractually::Contract.new(api, @template_id)

  contract.fill_fields(row)

  if @invite_user
    raise "Must have a First Name column to invite a user" if row["First Name"].nil? || row["First Name"] == ""
    raise "Must have a Last Name column to invite a user" if row["Last Name"].nil? || row["Last Name"] == ""
    raise "Must have an Email Address column to invite a user" if row["Email Address"].nil? || row["Email Address"] == ""

    name = "#{row["First Name"]} #{row["Last Name"]}"
    Contractually::Invite.new(api, contract, name, row["Email Address"])
  end
end
