provider "aws" {
  region = "us-east-1"
}

resource "aws_lex_bot" "pizza_bot" {
  name        = "KidPizzaBot"
  child_directed = true

  resource_specification {
    intent {
      name = "OrderPizza"

      sample_utterances {
        value = "I want pizza"
      }

      slot {
        name        = "PizzaSize"
        slot_type    = "PizzaSize"
        slot_type_version = "$LATEST"
      }

      slot {
        name        = "PizzaTopping"
        slot_type    = "PizzaTopping"
        slot_type_version = "$LATEST"
      }
    }
  }
}

resource "aws_lex_slot_type" "pizza_size" {
  name        = "PizzaSize"
  enumeration_values {
    value = "Small"
  }
  enumeration_values {
    value = "Medium"
  }
  enumeration_values {
    value = "Large"
  }
}

resource "aws_lex_slot_type" "pizza_topping" {
  name        = "PizzaTopping"
  enumeration_values {
    value = "Pepperoni"
  }
  enumeration_values {
    value = "Cheese"
  }
  enumeration_values {
    value = "Mushrooms"
  }
}