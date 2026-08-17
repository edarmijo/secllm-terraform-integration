provider "aws" {
  region = "us-east-1"
}

resource "aws_lex_bot" "pizza_bot" {
  name        = "KidPizzaBot"
  child_directed = true

  resource_specification {
    intent {
      name = "OrderPizza"

      sample_utterances = [
        "I want a pepperoni pizza",
        "Can I get a cheese pizza?"
      ]

      slot {
        name        = "PizzaType"
        slot_type    = "PizzaType"
        slot_elicitation_prompt {
          messages {
            content = "What kind of pizza would you like?"
          }
        }
      }

      fulfillment_activity {
        type = "ReturnIntent"
      }
    }

    intent {
      name = "GetPrice"

      sample_utterances = [
        "How much is this pizza?",
        "What is the price?"
      ]

      slot {
        name        = "PizzaType"
        slot_type    = "PizzaType"
      }

      fulfillment_activity {
        type = "ReturnIntent"
      }
    }

    abort_statement {
      messages {
        content = "I am unable to fulfill your request."
      }
    }
  }
}

resource "aws_lex_slot_type" "pizza_type" {
  name        = "PizzaType"
  enumeration_value {
    value = "Pepperoni"
  }
  enumeration_value {
    value = "Cheese"
  }
}