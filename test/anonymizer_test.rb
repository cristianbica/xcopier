# frozen_string_literal: true

require "test_helper"

class AnonymizerTest < Minitest::Test
  def test_anonymize_first_name
    anonymized_value = Xcopier::Anonymizer.anonymize("first_name", "John")
    refute_equal "John", anonymized_value

    anonymized_value = Xcopier::Anonymizer.anonymize("firstname", "John")
    refute_equal "John", anonymized_value
  end

  def test_anonymize_last_name
    anonymized_value = Xcopier::Anonymizer.anonymize("last_name", "Doe")
    refute_equal "Doe", anonymized_value

    anonymized_value = Xcopier::Anonymizer.anonymize("lastname", "Doe")
    refute_equal "Doe", anonymized_value
  end

  def test_anonymize_email
    anonymized_value = Xcopier::Anonymizer.anonymize("email", "john.doe@example.com")
    refute_equal "john.doe@example.com", anonymized_value

    anonymized_value = Xcopier::Anonymizer.anonymize("email_address", "john.doe@example.com")
    refute_equal "john.doe@example.com", anonymized_value
  end

  def test_anonymize_phone
    anonymized_value = Xcopier::Anonymizer.anonymize("phone", "123-456-7890")
    refute_equal "123-456-7890", anonymized_value
  end

  def test_anonymize_address
    anonymized_value = Xcopier::Anonymizer.anonymize("address", "123 Main St")
    refute_equal "123 Main St", anonymized_value
  end

  def test_anonymize_city
    anonymized_value = Xcopier::Anonymizer.anonymize("city", "New York")
    refute_equal "New York", anonymized_value
  end

  def test_anonymize_country
    anonymized_value = Xcopier::Anonymizer.anonymize("country", "USA")
    refute_equal "USA", anonymized_value
  end

  def test_anonymize_zip
    anonymized_value = Xcopier::Anonymizer.anonymize("zip", "10001")
    refute_equal "10001", anonymized_value
  end

  def test_anonymize_company
    anonymized_value = Xcopier::Anonymizer.anonymize("company", "Acme Corp")
    refute_equal "Acme Corp", anonymized_value

    anonymized_value = Xcopier::Anonymizer.anonymize("organization", "Acme Corp")
    refute_equal "Acme Corp", anonymized_value
  end

  def test_anonymize_non_matching
    value = "Some Value"
    anonymized_value = Xcopier::Anonymizer.anonymize("non_matching_field", value)
    assert_equal value, anonymized_value
  end
end
