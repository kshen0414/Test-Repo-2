// lib/services/text_extraction_service.dart

import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'dart:convert';

class TextExtractionService {
  late ChatOpenAI llm;
  late PromptTemplate extractionPrompt;

  TextExtractionService() {
    _initializeLangChain();
  }

  void _initializeLangChain() {
    
    // deleted

    extractionPrompt = PromptTemplate.fromTemplate('''
    You are a receipt parser for extracting structured data in JSON format. Focus on accuracy.

    ### Rules:
    1. **Merchant Name**:
    - Extract the main brand or store name only.
    - Remove extra details like "SDN BHD", "PLT", or branch locations.
    - Examples: "Watsons", "McDonald's".

    2. **Transaction Date**:
    - Extract the transaction date, not the printing date.
    - Common formats: DD/MM/YYYY, DD-MM-YYYY, DD MMM YYYY (e.g., "12 Nov 2024").
    - Ensure the year is between 2020 and 2025.
    - Output format: DD/MM/YYYY.

    3. **Total Amount**:
    - Extract the final total amount after taxes or charges.
    - Look for keywords: "TOTAL", "GRAND TOTAL".
    - Format: "RM XX.XX".

    4. **Tax Amount**:
    - Extract any taxes or service charges (e.g., SST, GST, VAT).
    - If none found, default to "RM 0.00".
    - Format: "RM XX.XX".

    ### Input:
    {text}

    ### Output:
    {{
    "merchant_name": string,
    "transaction_date": "DD/MM/YYYY",
    "total_amount": "RM XX.XX",
    "tax_amount": "RM XX.XX"
    }}
''');
  }

  Future<Map<String, dynamic>?> extractInformation(String text) async {
    try {
      if (text.isEmpty) {
        print('Empty text provided');
        return null;
      }

      // Generate and invoke the prompt
      final promptText = await extractionPrompt.invoke({'text': text});
      final response = await llm.invoke(promptText);

      // Handle the ChatResult response
      String jsonContent = response.output.content;

      // Clean up the markdown and any extra whitespace
      jsonContent =
          jsonContent.replaceAll('```json', '').replaceAll('```', '').trim();

      print('Cleaned JSON content: $jsonContent'); // Debug print

      try {
        final Map<String, dynamic> extractedData = jsonDecode(jsonContent);

        // Clean up merchant name if present
        if (extractedData['merchant_name'] != null) {
          String merchantName = extractedData['merchant_name'].toString();

          // Additional cleaning for merchant name
          merchantName = merchantName
              .replaceAll(
                  RegExp(r'\s+SDN\.?\s+BHD\.?', caseSensitive: false), '')
              .replaceAll(RegExp(r'\s+BHD\.?', caseSensitive: false), '')
              .replaceAll(RegExp(r'\s+PLT\.?', caseSensitive: false), '')
              .replaceAll(
                  RegExp(r'\s+PTE\.?\s+LTD\.?', caseSensitive: false), '')
              .replaceAll(RegExp(r'\s+ENTERPRISE', caseSensitive: false), '')
              .replaceAll(
                  RegExp(r'\([^)]*\)'), '') // Remove anything in parentheses
              .replaceAll(
                  RegExp(r'®|™'), '') // Remove registered/trademark symbols
              .trim();

          extractedData['merchant_name'] = merchantName;
        }

        // Ensure tax amount is properly formatted
        if (extractedData['tax_amount'] != null) {
          String taxAmount =
              extractedData['tax_amount'].toString().toUpperCase().trim();
          // Remove any existing currency symbols and spaces
          taxAmount = taxAmount.replaceAll('RM', '').trim();
          // Format as RM with proper spacing
          extractedData['tax_amount'] =
              taxAmount.isEmpty || taxAmount == '0' || taxAmount == '0.00'
                  ? 'RM 0.00'
                  : 'RM $taxAmount';
        } else {
          extractedData['tax_amount'] = 'RM 0.00';
        }

        print('Successfully parsed data: $extractedData');
        return extractedData;
      } catch (e) {
        print('JSON parsing error: $e');
        return null;
      }
    } catch (e) {
      print('Extraction error: $e');
      return null;
    }
  }
}
