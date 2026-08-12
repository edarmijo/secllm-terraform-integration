provider "aws" {
  region = "us-east-1"
}

resource "aws_lex_bot" "pizza_bot" {
  name        = "PizzaOrderingBot"
  child_directed = false

  resource_specification {
    intents {
      name = "OrderPizza"

      sample_utterances {
        utterance = "I want to order a pizza."
      }

      intent_confirmation_prompt {
        messages {
          content = "Would you like to proceed with your pizza order?"
          content_type = "PlainText"
        }
      }

      fulfillment_activity {
        type = "ReturnIntent"
      }
    }

    conclusion_statement {
      messages {
        content = "Thank you for your order. Your pizza will be delivered soon."
        content_type = "PlainText"
      }
    }
  }
}