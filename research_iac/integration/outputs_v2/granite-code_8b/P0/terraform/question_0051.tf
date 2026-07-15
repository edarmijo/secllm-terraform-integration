resource "aws_lexv2models_bot" "example" {
  bot_name           = "example-bot"
  role_arn            = aws_iam_role.example.arn
  data_sharing_type   = "External"

  intents {
    intent_id      = "ExampleIntent"
    intent_version = "1.0"

    slots {
      name              = "ExampleSlot"
      slot_type         = "AMAZON.AlphaNumeric"
      value_elicitation_prompt {
        messages {
          content_type = "PlainText"
          content      = "What is your example?"
        }
      }
    }
  }
}