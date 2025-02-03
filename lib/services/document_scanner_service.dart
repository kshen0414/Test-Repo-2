// lib/services/document_scanner_service.dart

import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:math' as math;

class DocumentScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  Future<Map<String, dynamic>> startScanning() async {
    try {
      // Keep using document scanner
      final documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          pageLimit: 1,
          mode: ScannerMode.full,
          isGalleryImport: true,
          documentFormat: DocumentFormat.jpeg,
        ),
      );

      final result = await documentScanner.scanDocument();
      
      if (result.images.isNotEmpty) {
        final imagePath = result.images.first;
        final String text = await _processImage(imagePath);
        
        return {
          'success': true,
          'imagePath': imagePath,
          'scannedText': text,
        };
      }

      return {
        'success': false,
        'error': 'No image captured'
      };

    } catch (e) {
      debugPrint('Error in document scanner: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  Future<String> _processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      debugPrint('\n=== OCR Recognition Results ===');
      debugPrint('Total blocks found: ${recognizedText.blocks.length}');
      
      // Get image bounds from recognized text blocks
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = 0;
      double maxY = 0;

      for (var block in recognizedText.blocks) {
        final box = block.boundingBox;
        minX = math.min(minX, box.left);
        minY = math.min(minY, box.top);
        maxX = math.max(maxX, box.right);
        maxY = math.max(maxY, box.bottom);
      }

      final imageWidth = maxX - minX;
      final imageHeight = maxY - minY;
      
      // Log blocks with normalized positions
      for (var i = 0; i < recognizedText.blocks.length; i++) {
        final block = recognizedText.blocks[i];
        final normalizedBox = _normalizeRect(block.boundingBox, minX, minY, imageWidth, imageHeight);
        
        debugPrint('\nBlock ${i + 1}:');
        debugPrint('Block text: ${block.text}');
        debugPrint('Block normalized position: $normalizedBox');
        
        for (var j = 0; j < block.lines.length; j++) {
          final line = block.lines[j];
          final confidence = _calculateConfidence(line);
          
          debugPrint('  Line ${j + 1}: "${line.text}" (confidence: $confidence)');
          debugPrint('  Line bounding box: ${line.boundingBox}');
        }
      }
      
      // Group lines using normalized positions
      Map<double, List<TextLine>> lineGroups = {};
      debugPrint('\n=== Text Line Grouping ===');
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          if (_calculateConfidence(line) < 0.7) continue;
          
          double normalizedY = (line.boundingBox.top - minY) / imageHeight;
          double key = lineGroups.keys.firstWhere(
            (k) => (k - normalizedY).abs() < 0.01,
            orElse: () => normalizedY,
          );
          lineGroups.putIfAbsent(key, () => []).add(line);
          debugPrint('Grouped line "${line.text}" at normalized y: ${(normalizedY * 100).toStringAsFixed(1)}%');
        }
      }
      
      // Sort and process groups
      debugPrint('\n=== Final Processed Text ===');
      StringBuffer processedText = StringBuffer();
      int groupIndex = 1;
      
      var sortedKeys = lineGroups.keys.toList()..sort();
      for (var key in sortedKeys) {
        var lines = lineGroups[key]!;
        lines.sort((a, b) => 
          ((a.boundingBox.left - minX) / imageWidth)
            .compareTo((b.boundingBox.left - minX) / imageWidth));
        
        String lineText = lines.map((l) => l.text.trim()).join(' ');
        processedText.writeln(lineText);
        debugPrint('Group $groupIndex: $lineText');
        groupIndex++;
      }
      
      debugPrint('\n=== Processing Complete ===\n');
      return processedText.toString();
      
    } catch (e) {
      debugPrint('\n=== OCR Processing Error ===');
      debugPrint('Error: $e');
      return 'Error processing image: $e';
    }
  }

  NormalizedRect _normalizeRect(Rect rect, double minX, double minY, double width, double height) {
    return NormalizedRect(
      left: (rect.left - minX) / width,
      top: (rect.top - minY) / height,
      right: (rect.right - minX) / width,
      bottom: (rect.bottom - minY) / height,
    );
  }

  double _calculateConfidence(TextLine line) {
    double confidence = 1.0;
    
    if (line.text.length < 2) confidence *= 0.8;
    if (RegExp(r'[^a-zA-Z0-9\s.,#@:$%()-]').hasMatch(line.text)) confidence *= 0.9;
    
    final ratio = line.boundingBox.height / line.boundingBox.width;
    if (ratio > 2.0 || ratio < 0.1) confidence *= 0.9;
    
    return confidence;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class NormalizedRect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  NormalizedRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  @override
  String toString() => 
    'NormalizedRect(${(left * 100).toStringAsFixed(1)}%, ' +
    '${(top * 100).toStringAsFixed(1)}%, ' +
    '${(right * 100).toStringAsFixed(1)}%, ' +
    '${(bottom * 100).toStringAsFixed(1)}%)';
}
