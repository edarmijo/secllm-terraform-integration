resource "aws_lex_bot" "pizza_ordering_bot" {
  name        = "pizza_ordering_bot"
  intents     = ["OrderPizza"]
  timezone    = "America/New_York"
  child_directed = true
  detect_sentiments = true

  intent {
    name               = "OrderPizza"
    intent_version     = "1.0"
    fulfillment_activity {
      type    = "ReturnIntent"
      message {
        groups = [
          {
            type  = "PlainText"
            text  = " ordering a pizza for you!"
          }
        ]
      }
    }
  }
}