//for handling database

// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create new user
  static Future<void> createUser(UserModel user, String userId) async {
    try {
      await _db.collection('users').doc(userId).set(user.toJson());
    } on FirebaseException catch (e) {
      print('Error creating user: $e');
      throw e;
    }
  }

  // Get user by ID
  static Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }
      return null;
    } on FirebaseException catch (e) {
      print('Error getting user: $e');
      throw e;
    }
  }

  // Update user
  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(userId).update(data);
    } on FirebaseException catch (e) {
      print('Error updating user: $e');
      throw e;
    }
  }

  // Delete user
  static Future<void> deleteUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();
    } on FirebaseException catch (e) {
      print('Error deleting user: $e');
      throw e;
    }
  }

  // Check if user exists by email
  static Future<bool> checkUserExists(String email) async {
    try {
      QuerySnapshot query = await _db
          .collection('users')
          .where('Email', isEqualTo: email)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      print('Error checking user existence: $e');
      throw e;
    }
  }

  // Get user by email
  static Future<UserModel?> getUserByEmail(String email) async {
    try {
      QuerySnapshot query = await _db
          .collection('users')
          .where('Email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        Map<String, dynamic> data = 
            query.docs.first.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }
      return null;
    } on FirebaseException catch (e) {
      print('Error getting user by email: $e');
      throw e;
    }
  }

  // Get all users
  static Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot query = await _db.collection('users').get();
      
      return query.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      print('Error getting all users: $e');
      throw e;
    }
  }

  // Helper method to handle Firestore exceptions
  static String getErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'not-found':
        return 'The requested document was not found.';
      case 'permission-denied':
        return 'You do not have permission to access this data.';
      case 'unavailable':
        return 'The service is currently unavailable. Please try again later.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}