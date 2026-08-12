resource "aws_lex_bot" "pizza_ordering" {
  name        = "PizzaOrderingBot"
  intents     = ["OrderPizzaIntent"]
  timezone    = "UTC"

  child_directed = false
  create_version  = true

  detect_sentiment = false

  voice_id = " salli"
}