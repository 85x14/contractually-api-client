require 'open-uri'
require 'csv'
require 'httparty'

module Contractually
  class Api
    include HTTParty

    def initialize(server, api_token)
      self.class.base_uri "#{server}/v0/"
      # Empty body required so we don't get a 411 error
      # See https://github.com/jnunemaker/httparty/issues/124
      @options = { query: { api_token: api_token }, body: "" }
    end

    def query(type, path, data)
      options = @options.clone
      options[:query].merge!(data)
      self.class.send(type, path, options)
    end

    def post(path, data)
      self.query(:post, path, data)
    end

    def put(path, data)
      self.query(:put, path, data)
    end
  end

  class Contract
    def initialize(api, template_id)
      @api = api

      data = { template_id: template_id }

      response = @api.post("/contracts", data)
      raise "Contract not created: #{response.body}" unless response.code == 201

      @contract_id = JSON.parse(response.body)["contract_id"]
      raise "Invalid contract id #{@contract_id}!" unless @contract_id.length == 5

      puts "Created contract #{@contract_id}"
    end

    def fill_fields(fields)
      # Have to URI encode the keys because nothing else does it for us
      data = { fields: Hash[fields.map{|k, v| [URI::encode(k), v] }] }

      response = @api.put("/contracts/#{@contract_id}/fields", data)
      raise "Could not fill fields #{fields}: #{response.body}" unless response.code == 204

      puts "Filled fields"
    end

    def contract_id
      @contract_id
    end

  end

  class Invite
    def initialize(api, contract, name, email)
      @api = api
      @contract_id = contract.contract_id

      data = {
        party: {
          organization: "",
          name: name,
          email: email,
          permissions: ["sign", "fill_fields"]
        }
      }

      response = @api.post("/contracts/#{@contract_id}/parties", data)
      raise "Could not invite user #{name} @ #{email}: #{response.body}" unless response.code == 201

      puts "Invited user #{name}"
    end
  end
end

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
