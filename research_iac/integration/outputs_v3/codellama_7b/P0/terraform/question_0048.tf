resource "aws_lex_bot" "pizza_ordering_kids" {
  name        = "PizzaOrderingKids"
  description = "A bot for ordering pizzas for kids"
  role        = aws_iam_role.lex_bot_role.arn
  locale      = "en-US"
  nlu_intent_confidence_threshold = 0.5
  idle_session_ttl_in_seconds = 600
  voice_id = "Salli"

  intent {
    name            = "OrderPizza"
    description     = "Order a pizza"
    fulfillment_code_hook {
      uri = "https://example.com/pizza-ordering-kids"
    }
  }

  slot {
    name        = "PizzaSize"
    description = "The size of the pizza"
    type        = "List"
    values = [
      "Small",
      "Medium",
      "Large"
    ]
  }

  slot {
    name        = "PizzaToppings"
    description = "The toppings on the pizza"
    type        = "List"
    values = [
      "Pepperoni",
      "Mushrooms",
      "Onions"
    ]
  }

  slot {
    name        = "PizzaCrust"
    description = "The crust of the pizza"
    type        = "List"
    values = [
      "Thin",
      "Thick",
      "Gluten-free"
    ]
  }

  slot {
    name        = "PizzaSauce"
    description = "The sauce on the pizza"
    type        = "List"
    values = [
      "Tomato",
      "Marinara",
      "Barbecue"
    ]
  }

  slot {
    name        = "PizzaCheese"
    description = "The cheese on the pizza"
    type        = "List"
    values = [
      "Regular",
      "Extra",
      "Extra-firm"
    ]
  }

  slot {
    name        = "PizzaDelivery"
    description = "The delivery method"
    type        = "List"
    values = [
      "Delivery",
      "Pickup"
    ]
  }

  slot {
    name        = "PizzaDeliveryAddress"
    description = "The delivery address"
    type        = "Address"
  }

  slot {
    name        = "PizzaDeliveryTime"
    description = "The delivery time"
    type        = "Time"
  }

  slot {
    name        = "PizzaDeliveryInstructions"
    description = "The delivery instructions"
    type        = "Text"
  }

  slot {
    name        = "PizzaPaymentMethod"
    description = "The payment method"
    type        = "List"
    values = [
      "Credit Card",
      "Cash",
      "Mobile Payment"
    ]
  }
}

resource "aws_iam_role" "lex_bot_role" {
  name = "LexBotRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lex.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

provider "aws" {
  region = "us-east-1"
}