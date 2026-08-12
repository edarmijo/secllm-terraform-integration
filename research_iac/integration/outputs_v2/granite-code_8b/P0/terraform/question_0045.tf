resource "aws_lex_bot" " OrderingPizzaBot" {
  name        = "OrderingPizzaBot"
  intents     = ["OrderPizzaIntent"]
  timezone    = "America/New_York"
  child_directed = false

  clarification_prompt {
    max_attempts       = 3
    messages           = [
      {
        content_type = "PlainText"
        content      = "I'm sorry, I didn't understand. Can you please try again?"
      }
    ]
  }
}