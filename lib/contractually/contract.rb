module Contractually
  class Contract
    attr_reader :contract_id

    def initialize(api, template_id)
      @api = api

      data = { template_id: template_id }

      response = @api.post("/contracts", data)
      raise "Contract not created: #{response.body}" unless response.code == 201

      @contract_id = JSON.parse(response.body)["contract_id"]
      raise "Invalid contract id #{@contract_id}!" unless @contract_id.length == 5
    end

    def set_title(title)
      data = { contract: { title: title } }

      response = @api.put("/contracts/#{@contract_id}", data)
      raise "Could set title: #{response.body}" unless response.code == 200
    end

    def fill_fields(fields)
      # Have to URI encode the keys because nothing else does it for us
      data = { fields: Hash[fields.map{|k, v| [URI::encode(k), v] }] }

      response = @api.put("/contracts/#{@contract_id}/fields", data)
      raise "Could not fill fields #{fields}: #{response.body}" unless response.code == 204
    end
  end
end
