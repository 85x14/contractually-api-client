require 'open-uri'
require 'csv'
require 'httparty'

class Contractually
  include HTTParty


  def initialize(server, api_token)
    self.class.base_uri "#{server}/v0/"
    # Empty body required so we don't get a 411 error
    # See https://github.com/jnunemaker/httparty/issues/124
    @options = { query: { api_token: api_token }, body: "" }
    #@options[:basic_auth] = {username: "staging", password: "!*pass9"}
  end

  def create_contract(template_id)
    options = @options.clone
    options[:query][:template_id] = template_id

    response = self.class.post("/contracts", options)
    raise "Contract not created: #{response.body}" unless response.code == 201

    @contract_id = JSON.parse(response.body)["contract_id"]
    raise "Invalid contract id #{@contract_id}!" unless @contract_id.size == 5

    puts "Created contract #{@contract_id}"
  end

  def fill_contract_fields(fields)
    options = @options.clone

    # Have to URI encode the keys because nothing else does it for us
    options[:query][:fields] = Hash[fields.map{|k, v| [URI::encode(k), v] }]

    response = self.class.put("/contracts/#{@contract_id}/fields", options)
    raise "Could not fill fields #{fields}: #{response.body}" unless response.code == 204

    puts "Filled fields"
  end

  def invite_user(name, email)
    options = @options.clone
    options[:query][:party] = {
      organization: "",
      name: name,
      email: email,
      permissions: ["sign", "fill_fields"]
    }

    response = self.class.post("/contracts/#{@contract_id}/parties", options)
    raise "Could not invite user #{name} @ #{email}: #{response.body}" unless response.code == 201

    puts "Invited user #{name}"
  end
end

@server = ARGV[0]
@api_token = ARGV[1]
@template_id = ARGV[2]
@filename = ARGV[3]

CSV.foreach(@filename, headers: true) do |row|
  contract = Contractually.new(@server, @api_token)

  contract.create_contract(@template_id)

  contract.fill_contract_fields(row)

  name = "#{row["First Name"]} #{row["Last Name"]}"
  contract.invite_user(name, row["Email Address"])
end
