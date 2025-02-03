import 'dart:convert';
import 'package:basic_ui_2/api_constants.dart';
import 'package:http/http.dart' as http;

class FinverseService {
  String? _customerAccessToken;
  String? _loginIdentityToken;

  Future<String> getCustomerAccessToken() async {
    print("Starting getCustomerAccessToken");
    if (_customerAccessToken != null) {
      print("Returning cached customer access token");
      return _customerAccessToken!;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.apiHost}/auth/customer/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': ApiConstants.clientId,
          'client_secret': ApiConstants.clientSecret,
          'grant_type': 'client_credentials',
        }),
      );

      print("Customer access token response status: ${response.statusCode}");
      print("Customer access token response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _customerAccessToken = jsonResponse['access_token'];
        print("Successfully obtained customer access token");
        return _customerAccessToken!;
      } else {
        throw Exception('Failed to get customer access token: ${response.body}');
      }
    } catch (e) {
      print("Error in getCustomerAccessToken: $e");
      rethrow;
    }
  }



  Future<String> generateLinkToken(String userId, String state) async {
    print("Starting generateLinkToken");
    try {
      final customerAccessToken = await getCustomerAccessToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.apiHost}/link/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $customerAccessToken',
        },
        body: jsonEncode({
          'client_id': ApiConstants.clientId,
          'user_id': userId,
          'redirect_uri': ApiConstants.redirectUri,
          'state': state,
          'response_mode': 'form_post',
          'response_type': 'code',
          'customer_app_id': ApiConstants.customerAppId,
          'grant_type': 'client_credentials',
        }),
      );

      print("Generate link token response status: ${response.statusCode}");
      print("Generate link token response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("Successfully generated link token");
        return jsonResponse['link_url'];
      } else {
        throw Exception('Failed to generate link token: ${response.body}');
      }
    } catch (e) {
      print("Error in generateLinkToken: $e");
      rethrow;
    }
  }


  // For 3.0 Link code
  Future<String> linkCode(String linkAuthCode) async {
    print("Starting linkCode");
    try {
      final customerAccessToken = await getCustomerAccessToken();

      final String endpoint = '${ApiConstants.apiHost}/auth/token';

      Map<String, String> headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer $customerAccessToken',
      };

      Map<String, String> body = {
        'client_id': ApiConstants.clientId,
        'code': linkAuthCode,
        'redirect_uri': ApiConstants.redirectUri,
        'grant_type': 'authorization_code',
      };

      final http.Response response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );

      print("Link code response status: ${response.statusCode}");
      print("Link code response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        String loginIdentityToken = jsonResponse['access_token'];
        _loginIdentityToken = loginIdentityToken; // Store the token
        print("Successfully obtained login identity token");
        return loginIdentityToken;
      } else {
        throw Exception('Failed to get login identity token: ${response.body}');
      }
    } catch (e) {
      print("Error in linkCode: $e");
      rethrow;
    }
  }


  // below is 4.0
  Future<void> _retrieveLoginIdentityToken() async {
    print("Retrieving login identity token");
    try {
      final customerAccessToken = await getCustomerAccessToken();
      
      // Construct the URL with query parameters
      final uri = Uri.parse('${ApiConstants.apiHost}/login_identity').replace(
        queryParameters: {
          'client_id': ApiConstants.clientId,
          'grant_type': 'client_credentials',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $customerAccessToken',
        },
      );

      print("Retrieve login identity token response status: ${response.statusCode}");
      print("Retrieve login identity token response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _loginIdentityToken = jsonResponse['access_token'];
        print("Successfully retrieved login identity token");
      } else {
        throw Exception('Failed to retrieve login identity token: ${response.body}');
      }
    } catch (e) {
      print("Error in _retrieveLoginIdentityToken: $e");
      rethrow;
    }
  }

  void setLoginIdentityToken(String token) {
    _loginIdentityToken = token;
    print("Login identity token set");
  }



// 5.0 For account retrieval

  Future<Map<String, dynamic>> getAccounts() async {
    print("Starting getAccounts");
    if (_loginIdentityToken == null) {
      throw Exception('Login identity token is not available');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiHost}/accounts'),
        headers: {'Authorization': 'Bearer $_loginIdentityToken'},
      );

      print("Get accounts response status: ${response.statusCode}");
      print("Get accounts response body: ${response.body}");

      if (response.statusCode == 200) {
        print("Successfully retrieved accounts data");
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get accounts: ${response.body}');
      }
    } catch (e) {
      print("Error in getAccounts: $e");
      rethrow;
    }
  }


// pollLoginIdentityStatus


  // Future<void> pollLoginIdentityStatus() async {
  //   print("Starting pollLoginIdentityStatus");
  //   if (_loginIdentityToken == null) {
  //     throw Exception('Login identity token is not available');
  //   }

  //   const maxAttempts = 20;
  //   const delay = Duration(seconds: 3);

  //   for (var i = 0; i < maxAttempts; i++) {
  //     try {
  //       final response = await http.get(
  //         Uri.parse('${ApiConstants.apiHost}/login_identity'),
  //         headers: {'Authorization': 'Bearer $_loginIdentityToken'},
  //       );

  //       print("Poll login identity status response status: ${response.statusCode}");
  //       print("Poll login identity status response body: ${response.body}");

  //       if (response.statusCode == 200) {
  //         final jsonResponse = jsonDecode(response.body);
  //         final status = jsonResponse['login_identity']['status'];
  //         print("Current login identity status: $status");
          
  //         if (status == 'DATA_RETRIEVAL_COMPLETE' || 
  //             status == 'DATA_RETRIEVAL_PARTIALLY_SUCCESSFUL' || 
  //             status == 'ERROR') {
  //           print("Login identity status polling complete");
  //           return;
  //         }
  //       } else {
  //         throw Exception('Failed to get login identity status: ${response.body}');
  //       }

  //       await Future.delayed(delay);
  //     } catch (e) {
  //       print("Error in pollLoginIdentityStatus attempt $i: $e");
  //       // Continue to next attempt
  //     }
  //   }

  //   throw Exception('Login identity status polling timed out');
  // }


  Future<void> handleWebViewSuccess() async {
    print("Handling WebView success");
    try {
      if (_loginIdentityToken == null) {
        await _retrieveLoginIdentityToken();
      }
      // await pollLoginIdentityStatus();
    } catch (e) {
      print("Error handling WebView success: $e");
      rethrow;
    }
  }

  
}