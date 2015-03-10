module Contractually
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
    end
  end
end
