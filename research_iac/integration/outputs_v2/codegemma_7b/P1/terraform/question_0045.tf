provider "aws" {
  region = "us-east-1"
}

resource "aws_lex_bot" "pizza_bot" {
  name = "PizzaOrderingBot"

  intents {
    name = "OrderPizza"

    samples {
      value = "I want to order a pizza."
    }

    slots {
      name = "PizzaSize"
      type = "STRING"
    }

    slots {
      name = "PizzaCrust"
      type = "STRING"
    }

    slots {
      name = "PizzaToppings"
      type = "LIST"
    }
  }

  fulfillment_activity {
    type = "ReturnIntent"
  }

  conclusion_statement {
    messages {
      content = "Thank you for your order. Your pizza will be delivered soon."
      content_type = "PlainText"
    }
  }
}