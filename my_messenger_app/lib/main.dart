import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'firebase_options.dart';
import 'firebase_service.dart';
import 'gemini_service.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(LifecycleWatcher(child: MyMessengerApp()));
}

class UserProfile {
  final String name;
  final String avatar;
  UserProfile({required this.name, required this.avatar});
}

class Message {
  final String text;
  final String senderId;
  final String senderAvatar;
  final DateTime timestamp;
  final bool isRyAI;

  Message({
    required this.text, 
    required this.senderId, 
    required this.senderAvatar, 
    required this.timestamp,
    this.isRyAI = false,
  });
}

class Chat {
  final UserProfile user;
  final List<Message> messages;
  Chat({required this.user, required this.messages});

  Chat copyWith({List<Message>? messages}) {
    return Chat(user: user, messages: messages ?? this.messages);
  }
}

// === Global Chat State for open chat tracking ===
class GlobalChatState {
  static String? currentlyOpenChatId;
}

class NotificationQueue {
  static final List<_NotificationData> _queue = [];
  static bool _showing = false;
  static AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (!_initialized) {
      WidgetsBinding.instance.addObserver(_NotificationQueueObserver());
      _initialized = true;
    }
  }

  static void show(
    BuildContext context,
    UserProfile fromUser,
    String message,
    String chatId,
    void Function(String replyText) onSendReply,
  ) {
    _ensureInitialized();
    _queue.add(_NotificationData(context, fromUser, message, chatId, onSendReply));
    _maybeShowNext();
  }

  static void _maybeShowNext() async {
    if (_showing || _queue.isEmpty) return;
    if (_lifecycleState != AppLifecycleState.resumed) return; // Only show if app is foreground
    _showing = true;
    final notif = _queue.removeAt(0);
    final overlay = Overlay.of(notif.context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 40,
        left: 20,
        right: 20,
        child: _InAppNotification(
          fromUser: notif.fromUser,
          message: notif.message,
          overlayEntry: overlayEntry,
          onTap: () {
            overlayEntry.remove();
            Navigator.of(notif.context).push(MaterialPageRoute(
              builder: (_) => ChatScreen(
                chat: Chat(user: notif.fromUser, messages: []),
                contactId: notif.chatId,
              ),
            ));
            _showing = false;
            Future.delayed(Duration(milliseconds: 400), _maybeShowNext);
          },
          onSendReply: (replyText) async {
            // Use current user info for reply
            final user = FirebaseService.auth.currentUser;
            String avatar = 'U';
            if (user != null) {
              if (user.displayName != null && user.displayName!.isNotEmpty) {
                avatar = user.displayName![0].toUpperCase();
              } else if (user.email != null && user.email!.isNotEmpty) {
                avatar = user.email![0].toUpperCase();
              }
            }
            final userId = FirebaseService.currentUserId;
            if (userId != null) {
              await FirebaseService.sendMessage(notif.chatId, replyText);
            }
            overlayEntry.remove();
            _showing = false;
            Future.delayed(Duration(milliseconds: 400), _maybeShowNext);
          },
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        _showing = false;
        Future.delayed(Duration(milliseconds: 400), _maybeShowNext);
      }
    });
  }

  static void updateLifecycle(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      Future.delayed(Duration(milliseconds: 200), _maybeShowNext);
    }
  }
}

class _NotificationData {
  final BuildContext context;
  final UserProfile fromUser;
  final String message;
  final String chatId;
  final void Function(String replyText) onSendReply;
  _NotificationData(this.context, this.fromUser, this.message, this.chatId, this.onSendReply);
}

class _NotificationQueueObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    NotificationQueue.updateLifecycle(state);
  }
}

// === New Contact Data Class ===
class _NewContactData {
  final String name;
  final String phone;
  final String avatar;
  
  _NewContactData({
    required this.name,
    required this.phone,
    this.avatar = '',
  });
}

// === Add Contact Dialog ===
class _AddContactDialog extends StatefulWidget {
  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _avatar = '';
  String _selectedCountryCode = '+1';
  final List<String> _countryCodes = ['+1', '+44', '+91', '+92', '+61', '+81', '+49', '+33', '+971'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF2A2A2A),
      title: Text('Add Contact', style: TextStyle(color: Color(0xFF8FBC8F))),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              style: TextStyle(color: Color(0xFF8FBC8F)),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Color(0xFF8FBC8F)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8FBC8F)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8FBC8F)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              onSaved: (value) => _name = value?.trim() ?? '',
            ),
            SizedBox(height: 16),
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedCountryCode,
                  dropdownColor: Color(0xFF2A2A2A),
                  style: TextStyle(color: Color(0xFF8FBC8F)),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountryCode = value!;
                    });
                  },
                  items: _countryCodes.map((code) {
                    return DropdownMenuItem(
                      value: code,
                      child: Text(code),
                    );
                  }).toList(),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    style: TextStyle(color: Color(0xFF8FBC8F)),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: Color(0xFF8FBC8F)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF8FBC8F)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF8FBC8F)),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a phone number';
                      }
                      return null;
                    },
                    onSaved: (value) => _phone = _selectedCountryCode + (value?.trim() ?? ''),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              style: TextStyle(color: Color(0xFF8FBC8F)),
              decoration: InputDecoration(
                labelText: 'Avatar (optional)',
                labelStyle: TextStyle(color: Color(0xFF8FBC8F)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8FBC8F)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8FBC8F)),
                ),
              ),
              maxLength: 1,
              onSaved: (value) => _avatar = value?.trim() ?? '',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Color(0xFF8FBC8F))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF8FBC8F),
            foregroundColor: Color(0xFF1A1A1A),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.of(context).pop(_NewContactData(
                name: _name,
                phone: _phone,
                avatar: _avatar,
              ));
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class MyMessengerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      title: 'RyText',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF1A1A1A),
        primaryColor: Color(0xFF2A2A2A),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF2A2A2A),
          secondary: Color(0xFF2A2A2A),
          background: Color(0xFF1A1A1A),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF8FBC8F),
            fontWeight: FontWeight.w500,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: Color(0xFF8FBC8F)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF3A3A3A), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF3A3A3A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF8FBC8F), width: 1),
          ),
          hintStyle: TextStyle(color: Color(0xFF8FBC8F).withOpacity(0.7)),
          labelStyle: TextStyle(color: Color(0xFF8FBC8F)),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2A2A2A),
          elevation: 2,
          foregroundColor: Color(0xFF8FBC8F),
          shape: CircleBorder(),
        ),
        cardTheme: CardThemeData(
          color: Color(0xFF2A2A2A),
          elevation: 2,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF8FBC8F)),
          bodyMedium: TextStyle(color: Color(0xFF8FBC8F)),
          bodySmall: TextStyle(color: Color(0xFF8FBC8F).withOpacity(0.8)),
          titleLarge: TextStyle(color: Color(0xFF8FBC8F), fontWeight: FontWeight.w500),
        ),
        iconTheme: IconThemeData(color: Color(0xFF8FBC8F)),
        drawerTheme: DrawerThemeData(
          backgroundColor: Color(0xFF1A1A1A),
        ),
      ),
      home: AuthGate(),
    );
  }
}

// ====== Global Message Listener Widget for notifications ======
class GlobalMessageListener extends StatefulWidget {
  final Widget child;
  GlobalMessageListener({required this.child});
  @override
  State<GlobalMessageListener> createState() => _GlobalMessageListenerState();
}

class _GlobalMessageListenerState extends State<GlobalMessageListener> {
  final Map<String, StreamSubscription<QuerySnapshot>> _messageSubscriptions = {};
  final Map<String, UserProfile> _userProfiles = {};
  StreamSubscription<QuerySnapshot>? _chatsSubscription;

  @override
  void initState() {
    super.initState();
    _listenToChats();
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  void _listenToChats() {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;
    _chatsSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) async {
      final chatIds = snapshot.docs.map((d) => d.id).toList();
      // Remove old listeners
      _messageSubscriptions.keys
          .where((id) => !chatIds.contains(id))
          .toList()
          .forEach((id) {
        _messageSubscriptions[id]?.cancel();
        _messageSubscriptions.remove(id);
      });
      // Add new listeners
      for (final doc in snapshot.docs) {
        final chatId = doc.id;
        if (_messageSubscriptions.containsKey(chatId)) continue;
        final participants = List<String>.from(doc['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
        if (otherUserId.isNotEmpty && !_userProfiles.containsKey(otherUserId)) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
          final data = userDoc.data() ?? {};
          _userProfiles[otherUserId] = UserProfile(
            name: data['name'] ?? 'User',
            avatar: (data['avatar'] ?? (data['name'] ?? 'U')).toString().substring(0, 1).toUpperCase(),
          );
        }
        _messageSubscriptions[chatId] = FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots()
            .listen((msgSnap) {
          if (msgSnap.docs.isNotEmpty) {
            final data = msgSnap.docs.first.data() as Map<String, dynamic>;
            final senderId = data['senderId'] ?? '';
            final text = data['text'] ?? '';
            // If not my message, and not in currently open chat, show notification
            if (senderId != userId && GlobalChatState.currentlyOpenChatId != chatId) {
              final fromUser = _userProfiles[otherUserId] ??
                  UserProfile(name: 'User', avatar: 'U');
              NotificationQueue.show(
                context,
                fromUser,
                text,
                chatId,
                (replyText) async {
                  // Use current user info for reply
                  final user = FirebaseService.auth.currentUser;
                  String avatar = 'U';
                  if (user != null) {
                    if (user.displayName != null && user.displayName!.isNotEmpty) {
                      avatar = user.displayName![0].toUpperCase();
                    } else if (user.email != null && user.email!.isNotEmpty) {
                      avatar = user.email![0].toUpperCase();
                    }
                  }
                  if (userId != null) {
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .collection('messages')
                        .add({
                      'text': replyText,
                      'senderId': userId,
                      'senderAvatar': avatar,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  }
                },
              );
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ====== Notification Popup Widget ======
class _InAppNotification extends StatefulWidget {
  final UserProfile fromUser;
  final String message;
  final VoidCallback onTap;
  final OverlayEntry overlayEntry;
  final void Function(String replyText) onSendReply;

  const _InAppNotification({
    required this.fromUser,
    required this.message,
    required this.overlayEntry,
    required this.onTap,
    required this.onSendReply,
  });

  @override
  State<_InAppNotification> createState() => _InAppNotificationState();
}

class _InAppNotificationState extends State<_InAppNotification> {
  bool _showReply = false;
  final TextEditingController _replyController = TextEditingController();
  bool _sending = false;

  void _handleReply() async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;
    setState(() { _sending = true; });
    widget.onSendReply(replyText);
    setState(() { _sending = false; });
    widget.overlayEntry.remove();
  }

  void _showReplyInput() {
    setState(() { _showReply = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedSlide(
        duration: Duration(milliseconds: 400),
        offset: Offset(0, _showReply ? 0 : -0.2),
        curve: Curves.easeOutBack,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { if (!_showReply) widget.onTap(); },
          onLongPress: _showReplyInput,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: _showReply ? 10 : 14),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF3A3A3A)),
            ),
            child: Stack(
              children: [
                _showReply
                    ? Row(
                  children: [
                    Icon(Icons.mail, color: Color(0xFF8FBC8F), size: 32),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        style: TextStyle(color: Color(0xFF8FBC8F)),
                        decoration: InputDecoration(
                          hintText: 'Reply to ${widget.fromUser.name}...',
                          hintStyle: TextStyle(color: Color(0xFF8FBC8F).withOpacity(0.7)),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFF1A1A1A),
                        ),
                        enabled: !_sending,
                        onSubmitted: (_) => _handleReply(),
                        autofocus: true,
                      ),
                    ),
                    SizedBox(width: 8),
                    _sending
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8FBC8F)),
                    )
                        : IconButton(
                      icon: Icon(Icons.send, color: Color(0xFF8FBC8F)),
                      onPressed: _handleReply,
                    ),
                  ],
                )
                    : Row(
                  children: [
                    Icon(Icons.mail, color: Color(0xFF8FBC8F), size: 32),
                    SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: Color(0xFF3A3A3A),
                      child: Text(widget.fromUser.avatar, style: TextStyle(color: Color(0xFF8FBC8F), fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.fromUser.name, style: TextStyle(color: Color(0xFF8FBC8F), fontWeight: FontWeight.w500)),
                          SizedBox(height: 2),
                          Text(widget.message, style: TextStyle(color: Color(0xFF8FBC8F).withOpacity(0.8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseService.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }
        if (snapshot.hasData) {
          return GlobalMessageListener(child: ChatListScreen());
        }
        return AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  String _name = '';
  String _avatar = '';
  String _phone = '';
  String _selectedCountryCode = '+1';
  String? _error;
  bool _loading = false;
  final List<String> _countryCodes = ['+1', '+44', '+91', '+92', '+61', '+81', '+49', '+33', '+971'];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await FirebaseService.signIn(_email, _password);
      } else {
        final phone = _selectedCountryCode + _phone;
        if (_phone.isEmpty) {
          setState(() { _error = 'Phone number is required.'; });
          return;
        }
        await FirebaseService.signUpWithPhone(_email, _password, _name, _avatar.isNotEmpty ? _avatar : _name[0].toUpperCase(), phone);
        // Also save phone in Firestore user profile
        final user = FirebaseService.auth.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': _name,
            'avatar': _avatar.isNotEmpty ? _avatar : _name[0].toUpperCase(),
            'email': _email,
            'phone': phone,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Card(
            color: Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLogin ? Icons.login : Icons.person_add,
                      size: 48,
                      color: Color(0xFF8FBC8F),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _isLogin ? 'Sign In' : 'Register', 
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.w500, 
                        color: Color(0xFF8FBC8F)
                      )
                    ),
                    SizedBox(height: 24),
                    if (!_isLogin) ...[
                      Row(
                        children: [
                          Icon(Icons.person, color: Color(0xFF8FBC8F), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('name'),
                              decoration: InputDecoration(
                                labelText: 'Name',
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              style: TextStyle(color: Color(0xFF8FBC8F)),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                              onSaved: (v) => _name = v!.trim(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.face, color: Color(0xFF8FBC8F), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('avatar'),
                              decoration: InputDecoration(
                                labelText: 'Avatar (initial or emoji)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              style: TextStyle(color: Color(0xFF8FBC8F)),
                              maxLength: 2,
                              onSaved: (v) => _avatar = v!.trim(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, color: Color(0xFF8FBC8F), size: 20),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFF3A3A3A)),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              dropdownColor: Color(0xFF2A2A2A),
                              style: TextStyle(color: Color(0xFF8FBC8F)),
                              underline: SizedBox(),
                              items: _countryCodes.map((code) => DropdownMenuItem(
                                value: code,
                                child: Text(code),
                              )).toList(),
                              onChanged: (val) => setState(() => _selectedCountryCode = val ?? '+1'),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('phone'),
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              style: TextStyle(color: Color(0xFF8FBC8F)),
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter your phone number' : null,
                              onSaved: (v) => _phone = v!.trim(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(Icons.email, color: Color(0xFF8FBC8F), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('email'),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            style: TextStyle(color: Color(0xFF8FBC8F)),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                            onSaved: (v) => _email = v!.trim(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.lock, color: Color(0xFF8FBC8F), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('password'),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            style: TextStyle(color: Color(0xFF8FBC8F)),
                            obscureText: true,
                            validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 chars' : null,
                            onSaved: (v) => _password = v!.trim(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    if (_error != null) ...[
                      Row(
                        children: [
                          Icon(Icons.error, color: Color(0xFF8FBC8F), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!, style: TextStyle(color: Color(0xFF8FBC8F))),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                    ],
                    _loading
                        ? CircularProgressIndicator(color: Color(0xFF8FBC8F))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2A2A2A),
                              foregroundColor: Color(0xFF8FBC8F),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              side: BorderSide(color: Color(0xFF3A3A3A)),
                            ),
                            onPressed: _submit,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_isLogin ? Icons.login : Icons.person_add, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  _isLogin ? 'Sign In' : 'Register', 
                                  style: TextStyle(color: Color(0xFF8FBC8F), fontWeight: FontWeight.w500)
                                ),
                              ],
                            ),
                          ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isLogin ? Icons.person_add : Icons.login, color: Color(0xFF8FBC8F).withOpacity(0.8), size: 20),
                          SizedBox(width: 8),
                          Text(
                            _isLogin ? 'Create an account' : 'Already have an account? Sign in', 
                            style: TextStyle(color: Color(0xFF8FBC8F).withOpacity(0.8))
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _envelopeController;
  late AnimationController _bgController;
  late Animation<double> _textScale;
  late Animation<double> _textOpacity;
  late Animation<double> _envelopeBounce;
  bool _envelopeClosed = false;

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    _envelopeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );
    _bgController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);
    _textScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutBack),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _envelopeBounce = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _envelopeController, curve: Curves.elasticOut),
    );
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _textController.forward();
    await Future.delayed(Duration(milliseconds: 600));
    setState(() {
      _envelopeClosed = true;
    });
    await _envelopeController.forward();
    await Future.delayed(Duration(milliseconds: 700));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatListScreen()),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _envelopeController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF2A2A2A),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _textScale,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child:                      Text(
                        'RyText',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8FBC8F),
                          letterSpacing: 1,
                        ),
                      ),
                  ),
                ),
                SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _envelopeController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _envelopeBounce.value),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 700),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        child: _envelopeClosed
                            ? Icon(Icons.mail, key: ValueKey('closed'), size: 64, color: Color(0xFF8FBC8F))
                            : Icon(Icons.mail_outline, key: ValueKey('open'), size: 64, color: Color(0xFF8FBC8F)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatListScreen extends StatefulWidget {
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late List<Chat> chats;
  late List<String> contactIds;
  StreamSubscription<QuerySnapshot>? _chatsSubscription;
  Map<String, UserProfile> userProfiles = {};
  StreamSubscription<QuerySnapshot>? _contactsSubscription;
  String _search = '';
  late UserProfile _currentUserProfile;

  @override
  void initState() {
    super.initState();
    chats = [];
    contactIds = [];
    _initializeUserProfile();
    // Don't call _listenToContacts() as it conflicts with _listenToChats()
    _upgradeUnregisteredContacts();
  }

  Future<void> _initializeUserProfile() async {
    final user = FirebaseService.auth.currentUser;
    if (user != null) {
      await FirebaseService.createUserProfile(
        user.uid,
        user.displayName ?? user.email?.split('@').first ?? 'User',
        '',
        user.email,
      );
      _currentUserProfile = UserProfile(
        name: user.displayName ?? user.email?.split('@').first ?? 'User',
        avatar: (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName![0].toUpperCase()
            : (user.email?.substring(0, 1).toUpperCase() ?? 'U'),
      );
    }
    _listenToChats();
  }

  void _listenToChats() {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;
    
    // Listen to the user's contacts, then fetch corresponding chats
    _chatsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .snapshots()
        .listen((contactsSnapshot) async {
      final newChats = <Chat>[];
      final newContactIds = <String>[];
      
      // Get all contacts that have a chatId (registered contacts)
      final contactsWithChats = contactsSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['registered'] == true && data['chatId'] != null;
      }).toList();
      
      // Fetch user profiles for all contacts
      final futures = <Future>[];
      for (var doc in contactsWithChats) {
        final data = doc.data();
        final chatId = data['chatId'];
        if (chatId != null) {
          // Get the other participant's userId from the chat
          futures.add(_fetchChatParticipant(chatId));
        }
      }
      
      await Future.wait(futures);
      
      // Build the chats list from contacts that the user has added
      for (var doc in contactsWithChats) {
        final data = doc.data();
        final chatId = data['chatId'];
        if (chatId != null) {
          final user = UserProfile(
            name: data['name'] ?? 'User',
            avatar: (data['avatar'] ?? (data['name'] ?? 'U')).toString().substring(0, 1).toUpperCase(),
          );
          newChats.add(Chat(user: user, messages: []));
          newContactIds.add(chatId); // Store the chatId
        }
      }
      
      setState(() {
        chats = newChats;
        contactIds = newContactIds;
      });
    });
  }

  Future<void> _fetchChatParticipant(String chatId) async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != FirebaseService.currentUserId, 
          orElse: () => ''
        );
        if (otherUserId.isNotEmpty) {
          await _fetchUserProfile(otherUserId);
        }
      }
    } catch (e) {
      print('Error fetching chat participant: $e');
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    if (!userProfiles.containsKey(userId)) {
      final data = await FirebaseService.getUserProfile(userId);
      if (data != null) {
        userProfiles[userId] = UserProfile(
          name: data['name'] ?? 'User',
          avatar: (data['avatar'] ?? (data['name'] ?? 'U')).toString().substring(0, 1).toUpperCase(),
        );
      }
    }
  }

  void updateChat(Chat updatedChat) {
    final index = chats.indexWhere((c) => c.user.name == updatedChat.user.name);
    if (index != -1) {
      setState(() {
        chats[index] = updatedChat;
      });
    }
  }

  void _handleSendReply(String userName, String replyText) {
    final index = chats.indexWhere((c) => c.user.name == userName);
    if (index != -1) {
      final chat = chats[index];
      final updatedChat = chat.copyWith(messages: [
        ...chat.messages,
        Message(
          text: replyText,
          senderId: FirebaseService.currentUserId ?? '',
          senderAvatar: _currentUserProfile.avatar,
          timestamp: DateTime.now(),
        ),
      ]);
      updateChat(updatedChat);
    }
  }

  void _listenToContacts() {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;
    _contactsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .snapshots()
        .listen((snapshot) {
      final newChats = <Chat>[];
      final newContactIds = <String>[];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final user = UserProfile(
          name: data['name'] ?? 'User',
          avatar: (data['avatar'] ?? (data['name'] ?? 'U')).toString().substring(0, 1).toUpperCase(),
        );
        newChats.add(Chat(user: user, messages: []));
        newContactIds.add(doc.id);
      }
      setState(() {
        chats = newChats;
        contactIds = newContactIds;
      });
    });
  }

  Future<void> _upgradeUnregisteredContacts() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;
    final contactsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .get();

    for (var doc in contactsSnap.docs) {
      final data = doc.data();
      if (data['registered'] == false && data['phone'] != null) {
        // Check if this phone is now registered
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: data['phone'])
            .get();
        if (usersSnap.docs.isNotEmpty) {
          final otherUserDoc = usersSnap.docs.first;
          final otherUserId = otherUserDoc.id;
          if (otherUserId == userId) continue; // Don't add yourself

          // Create chat if not exists
          final chatsSnap = await FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: userId)
              .get();
          String? chatId;
          for (var chatDoc in chatsSnap.docs) {
            final participants = List<String>.from(chatDoc['participants'] ?? []);
            if (participants.contains(otherUserId)) {
              chatId = chatDoc.id;
              break;
            }
          }
          if (chatId == null) {
            final chatDoc = await FirebaseFirestore.instance.collection('chats').add({
              'participants': [userId, otherUserId],
              'createdAt': FieldValue.serverTimestamp(),
            });
            chatId = chatDoc.id;
          }

          // Update contact to registered
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('contacts')
              .doc(doc.id)
              .update({
            'name': otherUserDoc['name'] ?? '',
            'avatar': otherUserDoc['avatar'] ?? '',
            'registered': true,
            'chatId': chatId,
          });
          
          // Also add current user to other user's contacts if not already exists
          final currentUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          final currentUserData = currentUserDoc.data();
          if (currentUserData != null) {
            // Check if current user is already in other user's contacts
            final otherUserContactsSnap = await FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .collection('contacts')
                .where('phone', isEqualTo: currentUserData['phone'])
                .get();
            
            if (otherUserContactsSnap.docs.isEmpty) {
              // Add current user to other user's contacts
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .collection('contacts')
                  .add({
                'name': currentUserData['name'] ?? '',
                'avatar': currentUserData['avatar'] ?? '',
                'registered': true,
                'chatId': chatId,
                'phone': currentUserData['phone'] ?? '',
              });
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    // _contactsSubscription?.cancel(); // Not using this anymore
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _search.isEmpty
        ? chats
        : chats.where((c) => c.user.name.toLowerCase().contains(_search.toLowerCase()) || c.user.avatar.toLowerCase().contains(_search.toLowerCase())).toList();
    return Stack(
      children: [
        // Simple background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF2A2A2A),
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          drawer: Drawer(
            backgroundColor: Color(0xFF1A1A1A),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0xFF3A3A3A),
                        child: Icon(Icons.person, color: Color(0xFF8FBC8F), size: 36),
                      ),
                      SizedBox(height: 12),
                      Text('Profile & Settings', style: TextStyle(color: Color(0xFF8FBC8F), fontWeight: FontWeight.w500, fontSize: 18)),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Color(0xFF8FBC8F)),
                  title: Text('Logout', style: TextStyle(color: Color(0xFF8FBC8F))),
                  onTap: () async {
                    await FirebaseService.signOut();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message, color: Color(0xFF8FBC8F)),
                SizedBox(width: 8),
                Text('RyText'),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.bug_report, color: Color(0xFF8FBC8F)),
                onPressed: () async {
                  // Test Firebase Service
                  try {
                    debugPrint('🧪 Testing Firebase Service...');
                    debugPrint('Current User ID: ${FirebaseService.currentUserId}');
                    
                    // Create a demo chat
                    final chatId = await FirebaseService.createChat('demo_other_user_456');
                    debugPrint('✅ Demo chat created: $chatId');
                    
                    // Send a test message
                    await FirebaseService.sendMessage(chatId, 'Hello from demo user!');
                    debugPrint('✅ Test message sent successfully');
                    
                  } catch (e) {
                    debugPrint('❌ Firebase Service Test Error: $e');
                  }

                  // Test Gemini Service
                  try {
                    debugPrint('🤖 Testing Gemini Service...');
                    await GeminiService.listAvailableModels();
                    
                    final response = await GeminiService.askRyAI('Hello, can you hear me?');
                    debugPrint('✅ RyAI Response: $response');
                    
                  } catch (e) {
                    debugPrint('❌ Gemini Service Test Error: $e');
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF8FBC8F)),
                  ),
                  style: TextStyle(color: Color(0xFF8FBC8F)),
                  cursorColor: Color(0xFF8FBC8F),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: filteredChats.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];
                    final lastMsg = chat.messages.isNotEmpty ? chat.messages.last : null;
                    // Fetch online/lastSeen status for each contact
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('name', isEqualTo: chat.user.name)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String status = '';
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>?;
                          if (data != null) {
                            if (data['online'] == true) {
                              status = 'Online';
                            } else if (data['lastSeen'] != null) {
                              final lastSeen = (data['lastSeen'] as Timestamp).toDate();
                              final diff = DateTime.now().difference(lastSeen);
                              if (diff.inMinutes < 1) {
                                status = 'Last seen just now';
                              } else if (diff.inMinutes < 60) {
                                status = 'Last seen ${diff.inMinutes} min ago';
                              } else if (diff.inHours < 24) {
                                status = 'Last seen ${diff.inHours} hr ago';
                              } else {
                                status = 'Last seen ${diff.inDays}d ago';
                              }
                            }
                          }
                        }
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 400 + index * 80),
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: Card(
                            color: Color(0xFF2A2A2A),
                            elevation: 2,
                            shadowColor: Colors.transparent,
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Color(0xFF3A3A3A),
                                    child: Text(chat.user.avatar, style: TextStyle(color: Color(0xFF8FBC8F), fontWeight: FontWeight.w500, fontSize: 22)),
                                  ),
                                  if (status == 'Online')
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF8FBC8F),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Color(0xFF2A2A2A), width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(chat.user.name, style: TextStyle(color: Color(0xFF8FBC8F), fontWeight: FontWeight.w500, fontSize: 18)),
                              subtitle: status.isNotEmpty ? Text(status, style: TextStyle(color: Color(0xFF8FBC8F).withOpacity(0.8), fontSize: 13)) : null,
                              trailing: lastMsg != null ? Text(
                                '${lastMsg.timestamp.hour.toString().padLeft(2, '0')}:${lastMsg.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(color: Color(0xFF8FBC8F).withOpacity(0.7), fontSize: 12),
                              ) : null,
                              onTap: () async {
                                // contactIds[index] is now the chatId directly
                                final chatId = contactIds[index];
                                
                                // Direct navigation to chat since we have the chatId
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      chat: Chat(user: chats[index].user, messages: []),
                                      contactId: chatId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: Tooltip(
            message: 'Add Contact',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: FloatingActionButton(
                backgroundColor: Color(0xFF2A2A2A),
                child: Icon(Icons.person_add, color: Color(0xFF8FBC8F)),
                onPressed: () async {
                  final newContact = await showDialog<_NewContactData>(
                    context: context,
                    builder: (context) => _AddContactDialog(),
                  );
                  if (newContact != null && newContact.name.trim().isNotEmpty && newContact.phone.trim().isNotEmpty) {
                    final userId = FirebaseService.currentUserId;
                    if (userId != null) {
                      // Search for registered user by phone
                      final usersSnap = await FirebaseFirestore.instance
                          .collection('users')
                          .where('phone', isEqualTo: newContact.phone.trim())
                          .get();
                      if (usersSnap.docs.isNotEmpty) {
                        // Registered user found
                        final otherUserDoc = usersSnap.docs.first;
                        final otherUserId = otherUserDoc.id;
                        // Prevent adding yourself
                        if (otherUserId == userId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('You cannot add yourself as a contact')),
                          );
                          return;
                        }
                        // Create chat if not exists
                        final chatsSnap = await FirebaseFirestore.instance
                            .collection('chats')
                            .where('participants', arrayContains: userId)
                            .get();
                        String? chatId;
                        for (var chatDoc in chatsSnap.docs) {
                          final participants = List<String>.from(chatDoc['participants'] ?? []);
                          if (participants.contains(otherUserId)) {
                            chatId = chatDoc.id;
                            break;
                          }
                        }
                        if (chatId == null) {
                          final chatDoc = await FirebaseFirestore.instance.collection('chats').add({
                            'participants': [userId, otherUserId],
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          chatId = chatDoc.id;
                        }
                        // Add to contacts for current user only
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('contacts')
                            .add({
                          'name': otherUserDoc['name'] ?? '',
                          'avatar': otherUserDoc['avatar'] ?? '',
                          'registered': true,
                          'chatId': chatId,
                          'phone': newContact.phone.trim(),
                        });
                        
                        // Note: We don't automatically add current user to other user's contacts
                        // They need to manually add each other for mutual visibility
                      } else {
                        // Unregistered user - add as contact
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('contacts')
                            .add({
                          'name': newContact.name.trim(),
                          'avatar': newContact.avatar.isNotEmpty ? newContact.avatar : newContact.name[0].toUpperCase(),
                          'registered': false,
                          'phone': newContact.phone.trim(),
                        });
                      }
                      // Always try to upgrade unregistered contacts after adding
                      await _upgradeUnregisteredContacts();
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showInAppNotification(BuildContext context, UserProfile fromUser, String message, void Function(String replyText) onSendReply, int chatIndex, {String? chatId, String? senderUserId}) {
    print('[DEBUG] _showInAppNotification called for fromUser=${fromUser.name}, chatId=$chatId, senderUserId=$senderUserId');
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 40,
        left: 20,
        right: 20,
        child: _InAppNotification(
          fromUser: fromUser,
          message: message,
          overlayEntry: overlayEntry,
          onTap: () {
            overlayEntry.remove();
            print('[DEBUG] Notification overlay removed for chatId=$chatId, senderUserId=$senderUserId');
            // Navigate to the chat if we have a valid chatId and senderUserId
            if (chatId != null && senderUserId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chat: Chat(user: fromUser, messages: []),
                    contactId: chatId,
                  ),
                ),
              );
            }
          },
          onSendReply: onSendReply,
        ),
      ),
    );
    overlay.insert(overlayEntry);
    print('[DEBUG] Notification overlay inserted for chatId=$chatId, senderUserId=$senderUserId');
  }
}




class ChatScreen extends StatefulWidget {
  final Chat chat;
  final String contactId; // This is actually the chatId for shared messaging
  final void Function(UserProfile fromUser, String message)? onOtherUserMessage;
  ChatScreen({required this.chat, required this.contactId, this.onOtherUserMessage});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  late UserProfile _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _initUserProfile();
    _listenToMessages();
  }

  Future<void> _initUserProfile() async {
    final user = FirebaseService.auth.currentUser;
    if (user != null) {
      _currentUserProfile = UserProfile(
               name: user.displayName ?? user.email?.split('@').first ?? 'User',
        avatar: (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName![0].toUpperCase()
            : (user.email?.substring(0, 1).toUpperCase() ?? 'U'),
      );
    } else {
      _currentUserProfile = UserProfile(name: 'Me', avatar: 'M');
    }
  }

  void _listenToMessages() {
    final userId = FirebaseService.currentUserId;
    final chatId = widget.contactId; // This should be the chatId, not contactId
    if (userId == null || chatId.isEmpty) return;
    
    // Set the currently open chat for notification purposes
    GlobalChatState.currentlyOpenChatId = chatId;
    
    // Listen to messages in the shared chat collection
    _messagesSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      final loaded = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Message(
          text: data['text'] ?? '',
          senderId: data['senderId'] ?? '',
          senderAvatar: data['senderAvatar'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRyAI: data['isRyAI'] ?? false,
        );
      }).toList();
      setState(() {
        _messages = loaded;
      });
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    // Clear the currently open chat when leaving
    GlobalChatState.currentlyOpenChatId = null;
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final userId = FirebaseService.currentUserId;
    final chatId = widget.contactId; // This should be the chatId
    if (userId == null || chatId.isEmpty) return;
    
    // Add user message to the shared chat collection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': userId,
      'senderAvatar': _currentUserProfile.avatar,
      'timestamp': FieldValue.serverTimestamp(),
      'isRyAI': false,
    });
    
    _controller.clear();
    
    // Check if it's a RyAI query
    if (GeminiService.isRyAIMessage(text)) {
      final question = GeminiService.extractQuestionFromRyAIMessage(text);
      
      // Get recent messages for context
      final recentMessages = _messages.take(5).map((m) => '${m.senderAvatar}: ${m.text}').join('\n');
      
      try {
        final aiResponse = await GeminiService.askRyAI(question, context: recentMessages);
        
        // Add RyAI response to the shared chat collection
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'text': aiResponse,
          'senderId': 'ryai',
          'senderAvatar': '🤖',
          'timestamp': FieldValue.serverTimestamp(),
          'isRyAI': true,
        });
      } catch (e) {
        print('RyAI Error: $e');
      }
    }
  }

  Widget _buildMessageBubble(Message msg, bool isMe, int index) {
    final isRyAI = msg.isRyAI;
    final bubbleGradient = isRyAI
        ? LinearGradient(colors: [Color(0xFF8FBC8F).withOpacity(0.2), Color(0xFF8FBC8F).withOpacity(0.1)])
        : isMe
            ? LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)])
            : LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)]);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 30),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Align(
        alignment: isRyAI ? Alignment.centerLeft : (isMe ? Alignment.centerRight : Alignment.centerLeft),
        child: Row(
          mainAxisAlignment: isRyAI ? MainAxisAlignment.start : (isMe ? MainAxisAlignment.end : MainAxisAlignment.start),
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && !isRyAI)
              Padding(
                padding: const EdgeInsets.only(right: 6.0, left: 2.0),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF8FBC8F),
                      child: Text(
                        msg.senderAvatar,
                        style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(0xFF8FBC8F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFF1A1A1A), width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isRyAI)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 2.0),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF8FBC8F), Color(0xFF7FAD7F)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF8FBC8F).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.transparent,
                        child: Text(
                          '🤖',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Color(0xFF8FBC8F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'AI',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                decoration: BoxDecoration(
                  gradient: bubbleGradient,
                  boxShadow: [
                    BoxShadow(
                      color: isMe ? Color(0xFF8FBC8F).withOpacity(0.25) : Color(0xFF2A2A2A),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  border: Border.all(
                    color: isRyAI
                        ? Color(0xFF8FBC8F).withOpacity(0.5)
                        : Color(0xFF8FBC8F).withOpacity(isMe ? 0.7 : 0.2),
                    width: isRyAI ? 2 : (isMe ? 2 : 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: TextStyle(color: Color(0xFF8FBC8F), fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Color(0xFF8FBC8F).withOpacity(0.54), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(left: 6.0, right: 2.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF8FBC8F),
                  child: Text(
                    msg.senderAvatar,
                    style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Color(0xFF8FBC8F)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF8FBC8F),
                  child: Text(widget.chat.user.avatar, style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 10),
                Text(widget.chat.user.name),
                SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFF8FBC8F),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final userId = FirebaseService.currentUserId;
                    final isMe = msg.senderId == userId;
                    return _buildMessageBubble(msg, isMe, index);
                  },
                ),
              ),
              Divider(height: 1, color: Color(0xFF8FBC8F).withOpacity(0.12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF8FBC8F).withOpacity(0.12),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: Color(0xFF8FBC8F)),
                          cursorColor: Color(0xFF8FBC8F),
                          decoration: InputDecoration(
                            hintText: 'Type a message... (Try @RyAI for AI help)',
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF8FBC8F), Color(0xFF8FBC8F)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF8FBC8F).withOpacity(0.5),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Color(0xFF1A1A1A), shadows: [Shadow(color: Color(0xFF8FBC8F), blurRadius: 8)]),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LifecycleWatcher extends StatefulWidget {
  final Widget child;
  LifecycleWatcher({required this.child});

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnline();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _setOnline();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _setOffline();
    }
  }

  void _setOnline() async {
    final userId = FirebaseService.currentUserId;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  void _setOffline() async {
    final userId = FirebaseService.currentUserId;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'online': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOffline();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
