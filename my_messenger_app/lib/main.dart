import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'firebase_service.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Verify Firebase
  debugPrint('Firebase initialized: ${Firebase.app().options.projectId}');
  
  // Test Firebase Service
  debugPrint('✅ Firebase Service: Demo user ID: ${FirebaseService.currentUserId}');
  
  // Set user online/offline on app lifecycle changes
  runApp(LifecycleWatcher(child: MyMessengerApp()));
}

class UserProfile {
  final String name;
  final String avatar;
  UserProfile({required this.name, required this.avatar});
}

class Message {
  final String text;
  final String sender;
  final DateTime timestamp;

  Message({required this.text, required this.sender, required this.timestamp});
}

class Chat {
  final UserProfile user;
  final List<Message> messages;
  Chat({required this.user, required this.messages});

  Chat copyWith({List<Message>? messages}) {
    return Chat(user: user, messages: messages ?? this.messages);
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
        scaffoldBackgroundColor: Colors.transparent,
        primaryColor: Color(0xFF7C3AED),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFF9F7AEA),
          background: Color(0xFF181829),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
            shadows: [Shadow(color: Color(0xFF7C3AED).withOpacity(0.2), blurRadius: 8)],
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF23234A).withOpacity(0.7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.white54),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF7C3AED),
          elevation: 12,
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.08),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
      ),
      home: AuthGate(),
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
          return ChatListScreen();
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
        await FirebaseService.signUpWithPhone(_email, _password, _name, _avatar.isNotEmpty ? _avatar : _name[0].toUpperCase(), phone);
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
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Card(
            color: Color(0xFF23234A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isLogin ? 'Sign In' : 'Register', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                    SizedBox(height: 24),
                    if (!_isLogin) ...[
                      TextFormField(
                        key: ValueKey('name'),
                        decoration: InputDecoration(labelText: 'Name'),
                        style: TextStyle(color: Colors.white),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                        onSaved: (v) => _name = v!.trim(),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        key: ValueKey('avatar'),
                        decoration: InputDecoration(labelText: 'Avatar (initial or emoji)'),
                        style: TextStyle(color: Colors.white),
                        maxLength: 2,
                        onSaved: (v) => _avatar = v!.trim(),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: _selectedCountryCode,
                            dropdownColor: Color(0xFF23234A),
                            style: TextStyle(color: Colors.white),
                            items: _countryCodes.map((code) => DropdownMenuItem(
                              value: code,
                              child: Text(code),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedCountryCode = val ?? '+1'),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('phone'),
                              decoration: InputDecoration(labelText: 'Phone Number'),
                              style: TextStyle(color: Colors.white),
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter your phone number' : null,
                              onSaved: (v) => _phone = v!.trim(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                    TextFormField(
                      key: ValueKey('email'),
                      decoration: InputDecoration(labelText: 'Email'),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                      onSaved: (v) => _email = v!.trim(),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      key: ValueKey('password'),
                      decoration: InputDecoration(labelText: 'Password'),
                      style: TextStyle(color: Colors.white),
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 chars' : null,
                      onSaved: (v) => _password = v!.trim(),
                    ),
                    SizedBox(height: 24),
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: Colors.redAccent)),
                      SizedBox(height: 12),
                    ],
                    _loading
                        ? CircularProgressIndicator(color: Color(0xFF7C3AED))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7C3AED),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            ),
                            onPressed: _submit,
                            child: Text(_isLogin ? 'Sign In' : 'Register'),
                          ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin ? 'Create an account' : 'Already have an account? Sign in', style: TextStyle(color: Colors.white54)),
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
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(Color(0xFF7C3AED), Color(0xFF181829), _bgController.value)!,
                      Color.lerp(Color(0xFF23234A), Color(0xFF7C3AED), 1 - _bgController.value)!,
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _textScale,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Text(
                      'RyText',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                        letterSpacing: 2,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                        ],
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
                            ? Icon(Icons.mail, key: ValueKey('closed'), size: 64, color: Colors.white)
                            : Icon(Icons.mail_outline, key: ValueKey('open'), size: 64, color: Colors.white),
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

  @override
  void initState() {
    super.initState();
    chats = [];
    contactIds = [];
    _initializeUserProfile();
    _listenToContacts();
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
    }
    _listenToChats();
  }

  void _listenToChats() {
    _chatsSubscription = FirebaseService.getUserChatsStream().listen((snapshot) async {
      final newChats = <Chat>[];
      final futures = <Future>[];
      final userId = FirebaseService.currentUserId;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
        if (otherUserId.isNotEmpty) {
          futures.add(_fetchUserProfile(otherUserId));
        }
      }
      await Future.wait(futures);
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != FirebaseService.currentUserId, orElse: () => '');
        if (otherUserId.isNotEmpty && userProfiles.containsKey(otherUserId)) {
          newChats.add(Chat(
            user: userProfiles[otherUserId]!,
            messages: [],
          ));
        }
      }
      setState(() {
        chats = newChats;
      });
    });
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
          sender: FirebaseService.currentUserName ?? 'Me',
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

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _contactsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _search.isEmpty
        ? chats
        : chats.where((c) => c.user.name.toLowerCase().contains(_search.toLowerCase()) || c.user.avatar.toLowerCase().contains(_search.toLowerCase())).toList();
    return Stack(
      children: [
        // Glassmorphic background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF23234A), Color(0xFF7C3AED).withOpacity(0.7), Color(0xFF181829)],
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(color: Colors.transparent),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          drawer: Drawer(
            backgroundColor: Color(0xFF23234A).withOpacity(0.95),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF23234A)]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0xFF7C3AED),
                        child: Icon(Icons.person, color: Colors.white, size: 36),
                      ),
                      SizedBox(height: 12),
                      Text('Profile & Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Color(0xFF7C3AED)),
                  title: Text('Logout', style: TextStyle(color: Colors.white)),
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
                Icon(Icons.message, color: Color(0xFF7C3AED)),
                SizedBox(width: 8),
                Text('RyText'),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.bug_report, color: Color(0xFF7C3AED)),
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
                    prefixIcon: Icon(Icons.search, color: Color(0xFF7C3AED)),
                  ),
                  style: TextStyle(color: Colors.white),
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
                            color: Colors.white.withOpacity(0.10),
                            elevation: 10,
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Color(0xFF7C3AED),
                                    child: Text(chat.user.avatar, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                                  ),
                                  if (status == 'Online')
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(chat.user.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: status.isNotEmpty ? Text(status, style: TextStyle(color: Colors.white70, fontSize: 13)) : null,
                              trailing: lastMsg != null ? Text(
                                '${lastMsg.timestamp.hour.toString().padLeft(2, '0')}:${lastMsg.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ) : null,
                              onTap: () async {
                                final isRegistered = contactIds[index].length == 28; // Firestore UIDs are 28 chars
                                final contactDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseService.currentUserId)
                                    .collection('contacts')
                                    .doc(contactIds[index])
                                    .get();
                                final data = contactDoc.data() as Map<String, dynamic>?;
                                if (data != null && data['registered'] == true && data['chatId'] != null) {
                                  // Open real-time chat using chatId
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegisteredChatScreen(
                                        chatId: data['chatId'],
                                        contact: chats[index].user,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Not registered, show Invite
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('This contact is not on RyText. Invite them to join!')),
                                  );
                                }
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
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF7C3AED).withOpacity(0.5),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
                shape: BoxShape.circle,
              ),
              child: FloatingActionButton(
                backgroundColor: Color(0xFF7C3AED),
                child: Icon(Icons.person_add, color: Colors.white),
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
                        // Create chat in 'chats' collection (if not already exists)
                        final chatsSnap = await FirebaseFirestore.instance
                            .collection('chats')
                            .where('participants', arrayContains: userId)
                            .get();
                        String? chatId;
                        for (var doc in chatsSnap.docs) {
                          final participants = List<String>.from(doc['participants'] ?? []);
                          if (participants.contains(otherUserId)) {
                            chatId = doc.id;
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
                        // Save contact as registered user
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('contacts')
                            .doc(otherUserId)
                            .set({
                          'name': otherUserDoc['name'] ?? '',
                          'avatar': otherUserDoc['avatar'] ?? '',
                          'phone': newContact.phone.trim(),
                          'chatId': chatId,
                          'registered': true,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      } else {
                        // Not a registered user, save as regular contact
                        final contactId = DateTime.now().millisecondsSinceEpoch.toString();
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('contacts')
                            .doc(contactId)
                            .set({
                          'name': newContact.name.trim(),
                          'avatar': newContact.avatar.trim().isNotEmpty ? newContact.avatar.trim() : newContact.name.trim()[0].toUpperCase(),
                          'phone': newContact.phone.trim(),
                          'registered': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
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

  void _showInAppNotification(BuildContext context, UserProfile fromUser, String message, void Function(String replyText) onSendReply, int chatIndex) {
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
            // Navigate to the chat with fromUser
            final chat = chats[chatIndex];
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chat: chat,
                  contactId: contactIds[chatIndex],
                  onOtherUserMessage: (fromUser, message) {
                    if (fromUser.name != chat.user.name) {
                      _showInAppNotification(context, fromUser, message, onSendReply, chatIndex);
                    }
                  },
                ),
              ),
            );
          },
          onSendReply: onSendReply,
        ),
      ),
    );
    overlay.insert(overlayEntry);
  }
}

class _InAppNotification extends StatefulWidget {
  final UserProfile fromUser;
  final String message;
  final VoidCallback onTap;
  final OverlayEntry overlayEntry;
  final void Function(String replyText) onSendReply;
  const _InAppNotification({required this.fromUser, required this.message, required this.overlayEntry, required this.onTap, required this.onSendReply});

  @override
  State<_InAppNotification> createState() => _InAppNotificationState();
}

class _InAppNotificationState extends State<_InAppNotification> {
  bool _showReply = false;
  final TextEditingController _replyController = TextEditingController();
  bool _sending = false;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _autoDismissTimer = Timer(Duration(seconds: 5), () {
      if (!_showReply && widget.overlayEntry.mounted) widget.overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _handleReply() async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;
    setState(() { _sending = true; });
    widget.onSendReply(replyText);
    setState(() { _sending = false; });
    widget.overlayEntry.remove();
  }

  void _showReplyInput() {
    _autoDismissTimer?.cancel();
    setState(() {
      _showReply = true;
    });
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
          onTap: () {
            if (!_showReply) widget.onTap();
          },
          onLongPress: _showReplyInput,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: _showReply ? 10 : 14),
            decoration: BoxDecoration(
              color: Color(0xFF23234A).withOpacity(0.98),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF7C3AED).withOpacity(0.18),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
              border: Border.all(color: Color(0xFF7C3AED).withOpacity(0.18)),
            ),
            child: Stack(
              children: [
                _showReply
                    ? Row(
                  children: [
                    Icon(Icons.mail, color: Color(0xFF7C3AED), size: 32),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Reply to ${widget.fromUser.name}...',
                          hintStyle: TextStyle(color: Colors.white54),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFF181829),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                    )
                        : IconButton(
                      icon: Icon(Icons.send, color: Color(0xFF7C3AED)),
                      onPressed: _handleReply,
                    ),
                  ],
                )
                    : Row(
                  children: [
                    Icon(Icons.mail, color: Color(0xFF7C3AED), size: 32),
                    SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: Color(0xFF7C3AED),
                      child: Text(widget.fromUser.avatar, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.fromUser.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text(widget.message, style: TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
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

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final String contactId;
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
    final contactId = widget.contactId;
    if (userId == null || contactId.isEmpty) return;
    _messagesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contactId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      final loaded = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Message(
          text: data['text'] ?? '',
          sender: data['sender'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final userId = FirebaseService.currentUserId;
    final contactId = widget.contactId;
    if (userId == null || contactId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contactId)
        .collection('messages')
        .add({
      'text': text,
      'sender': _currentUserProfile.name,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  Widget _buildMessageBubble(Message msg, bool isMe, int index) {
    final bubbleGradient = isMe
        ? LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)])
        : LinearGradient(colors: [Color(0xFF23234A), Color(0xFF23234A).withOpacity(0.7)]);
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
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(right: 6.0, left: 2.0),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF7C3AED),
                      child: Text(
                        widget.chat.user.avatar,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
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
                      color: isMe ? Color(0xFF7C3AED).withOpacity(0.18) : Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
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
                  backgroundColor: Color(0xFF7C3AED),
                  child: Text(
                    _currentUserProfile.avatar,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF23234A), Color(0xFF7C3AED), Color(0xFF181829)],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context, widget.chat.copyWith(messages: _messages));
              },
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF7C3AED),
                  child: Text(widget.chat.user.avatar, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 10),
                Text(widget.chat.user.name),
                SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
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
                    final isMe = msg.sender == _currentUserProfile.name;
                    return _buildMessageBubble(msg, isMe, index);
                  },
                ),
              ),
              Divider(height: 1, color: Colors.white12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF23234A),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF7C3AED).withOpacity(0.12),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
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
                        gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF7C3AED).withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
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

// Add dialog and data class for new contact
class _NewContactData {
  final String name;
  final String avatar;
  final String phone;
  _NewContactData(this.name, this.avatar, this.phone);
}

class _AddContactDialog extends StatefulWidget {
  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+1';
  final List<String> _countryCodes = ['+1', '+44', '+91', '+92', '+61', '+81', '+49', '+33', '+971'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF23234A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Add Contact', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Color(0xFF181829),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _avatarController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Avatar (initial or emoji)',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Color(0xFF181829),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            maxLength: 2,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              DropdownButton<String>(
                value: _selectedCountryCode,
                dropdownColor: Color(0xFF23234A),
                style: TextStyle(color: Colors.white),
                items: _countryCodes.map((code) => DropdownMenuItem(
                  value: code,
                  child: Text(code),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCountryCode = val ?? '+1'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF181829),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF7C3AED),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final phone = _selectedCountryCode + _phoneController.text.trim();
            Navigator.of(context).pop(_NewContactData(_nameController.text, _avatarController.text, phone));
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class RegisteredChatScreen extends StatefulWidget {
  final String chatId;
  final UserProfile contact;
  RegisteredChatScreen({required this.chatId, required this.contact});

  @override
  State<RegisteredChatScreen> createState() => _RegisteredChatScreenState();
}

class _RegisteredChatScreenState extends State<RegisteredChatScreen> {
  late List<Message> messages;
  late TextEditingController _controller;
  late ScrollController _scrollController;
  late StreamSubscription<QuerySnapshot> _messagesSubscription;

  @override
  void initState() {
    super.initState();
    messages = [];
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _listenToMessages();
  }

  void _listenToMessages() {
    _messagesSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      final loaded = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Message(
          text: data['text'] ?? '',
          sender: data['sender'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      setState(() {
        messages = loaded;
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
    _messagesSubscription.cancel();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': text,
      'sender': widget.contact.name,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF23234A), Color(0xFF7C3AED), Color(0xFF181829)],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context, Chat(user: widget.contact, messages: messages));
              },
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF7C3AED),
                  child: Text(widget.contact.avatar, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 10),
                Text(widget.contact.name),
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
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.sender == widget.contact.name;
                    return _buildMessageBubble(msg, isMe, index);
                  },
                ),
              ),
              Divider(height: 1, color: Colors.white12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF23234A),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF7C3AED).withOpacity(0.12),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
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
                        gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF7C3AED).withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
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

  Widget _buildMessageBubble(Message msg, bool isMe, int index) {
    final bubbleGradient = isMe
        ? LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)])
        : LinearGradient(colors: [Color(0xFF23234A), Color(0xFF23234A).withOpacity(0.7)]);
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
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(right: 6.0, left: 2.0),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF7C3AED),
                      child: Text(
                        widget.contact.avatar,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
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
                      color: isMe ? Color(0xFF7C3AED).withOpacity(0.18) : Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
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
                  backgroundColor: Color(0xFF7C3AED),
                  child: Text(
                    widget.contact.avatar,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LifecycleWatcher extends StatefulWidget {
  final Widget child;
  const LifecycleWatcher({required this.child});
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

  void _setOnline() async {
    await FirebaseService.setUserOnlineStatus(true);
  }
  void _setOffline() async {
    await FirebaseService.setUserOnlineStatus(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _setOffline();
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
