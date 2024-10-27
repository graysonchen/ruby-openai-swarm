def escalate_to_agent(reason = nil)
  reason ? "Escalating to agent: #{reason}" : "Escalating to agent"
end

def valid_to_change_flight
  "Customer is eligible to change flight"
end

def change_flight
  "Flight was successfully changed!"
end

def initiate_refund
  status = "Refund initiated"
  status
end

def initiate_flight_credits
  status = "Successfully initiated flight credits"
  status
end

def case_resolved
  "Case resolved. No further questions."
end

def initiate_baggage_search
  "Baggage was found!"
end
