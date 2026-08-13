resource "aws_lexv2models_bot" "example" {
  name = "example_bot"
  child_directed = false
  locale = "en-US"
  abort_statement {
    messages {
      content = "I am unable to fulfill your request."
      content_type = "PlainText"
    }
  }
  clarification_prompt {
    messages {
      content = "I am unable to understand your request. Please try again."
      content_type = "PlainText"
    }
  }
  sample_utterances {
    utterance = "hello"
  }
  sample_utterances {
    utterance = "goodbye"
  }
}