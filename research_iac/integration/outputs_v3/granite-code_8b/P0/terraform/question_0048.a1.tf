resource "aws_lex_bot" "OrderingPizzasForKids" {
  name        = "OrderingPizzasForKids"
  intents     = ["OrderPizzaIntent"]
  timezone    = "America/New_York"
  child_directed = true
  detect_sentiments = true
}

resource "aws_lex_intent" "OrderPizzaIntent" {
  name        = "OrderPizzaIntent"
  slots       = ["Size", "Topping"]
  fulfillment_activity {
    type    = "ReturnIntent"
    message {
      groups = [
        {
          type    = "PlainText"
          content = "Thank you for ordering your pizza! We will have it ready for you in no time."
        }
      ]
    }
  }
}

resource "aws_lex_slot_type" "Size" {
  name        = "Size"
  values      = ["Small", "Medium", "Large"]
  value_selection_strategy = "TOP_RESOLUTION"
}

resource "aws_lex_slot_type" "Topping" {
  name        = "Topping"
  values      = ["Pepperoni", "Mushrooms", "Onions", "Sausage"]
  value_selection_strategy = "TOP_RESOLUTION"
}