resource "aws_lexv2models_bot" "example" {
  name               = var.bot_name
  child_directed     = false
  locale             = "en-US"
  abort_statement {
    messages {
      content = "Sorry, I am not able to fulfill your request."
      content_type = "PlainText"
    }
  }
  clarification_prompt {
    messages {
      content = "I am not sure what you mean. Can you please rephrase your request?"
      content_type = "PlainText"
    }
  }
  intents {
    name = "ExampleIntent"
    sample_utterances {
      value = "hello"
    }
    sample_utterances {
      value = "hi"
    }
    fulfillment_activity {
      type = "ReturnIntent"
    }
  }
  version = "1.0"
}