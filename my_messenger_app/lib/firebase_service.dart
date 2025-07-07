import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;
  
  // Get current user display name
  static String? get currentUserName => _auth.currentUser?.displayName;
  
  // Get current user email
  static String? get currentUserEmail => _auth.currentUser?.email;
  
  // Sign up with email and password
  static Future<UserCredential> signUp(String email, String password, String name, String avatar) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user?.updateDisplayName(name);
    await createUserProfile(credential.user!.uid, name, avatar, email);
    return credential;
  }
  
  // Sign in with email and password
  static Future<UserCredential> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return credential;
  }
  
  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Create or update user profile
  static Future<void> createUserProfile(String userId, String name, String avatar, String? email, [String? phone]) async {
    final safeName = (name.isNotEmpty ? name : 'User');
    final safeAvatar = (avatar.isNotEmpty ? avatar : (safeName[0].toUpperCase()));
    await _firestore.collection('users').doc(userId).set({
      'name': safeName,
      'avatar': safeAvatar,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }
  
  // Create a new chat
  static Future<String> createChat(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');
    // Create consistent chat ID by sorting user IDs
    final participants = [userId, otherUserId]..sort();
    final chatId = participants.join('_');
    final chatRef = _firestore.collection('chats').doc(chatId);
    final existingChat = await chatRef.get();
    if (!existingChat.exists) {
      await chatRef.set({
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }
  
  // Get user's chats stream
  static Stream<QuerySnapshot> getUserChatsStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Get chat by ID
  static Future<DocumentSnapshot> getChatById(String chatId) async {
    return await _firestore.collection('chats').doc(chatId).get();
  }
  
  // Send message
  static Future<void> sendMessage(String chatId, String text) async {
    final messageData = {
      'chatId': chatId,
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
    
    // Add message to messages collection
    await _firestore.collection('messages').add(messageData);
    
    // Update chat's last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
  
  // Get messages stream for a chat
  static Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
  
  // Get all users
  static Stream<QuerySnapshot> getAllUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Save contact for current user
  static Future<void> addContact(String contactUserId, {String? name, String? avatar}) async {
    if (currentUserId == null) return;
    final safeName = (name != null && name.isNotEmpty) ? name : 'User';
    final safeAvatar = (avatar != null && avatar.isNotEmpty) ? avatar : (safeName[0].toUpperCase());
    await _firestore.collection('users').doc(currentUserId).collection('contacts').doc(contactUserId).set({
      'name': safeName,
      'avatar': safeAvatar,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Get contacts for current user
  static Stream<QuerySnapshot> getContactsStream() {
    if (currentUserId == null) {
      // Return an empty stream if not signed in
      return const Stream.empty();
    }
    return _firestore.collection('users').doc(currentUserId).collection('contacts').snapshots();
  }
  
  static Future<UserCredential> signUpWithPhone(String email, String password, String name, String avatar, String phone) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user?.updateDisplayName(name);
    await createUserProfile(credential.user!.uid, name, avatar, email, phone);
    return credential;
  }
  
  static FirebaseAuth get auth => _auth;
  
  static Future<void> setUserOnlineStatus(bool online) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'online': online,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
} 