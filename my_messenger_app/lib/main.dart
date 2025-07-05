import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Verify Firebase
  debugPrint('Firebase initialized: ${Firebase.app().options.projectId}');
  
  runApp(MyMessengerApp());
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

final UserProfile me = UserProfile(name: 'Me', avatar: 'M');
final List<UserProfile> demoUsers = [
  UserProfile(name: 'Alice', avatar: 'A'),
  UserProfile(name: 'Bob', avatar: 'B'),
];

class MyMessengerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([ // Lock portrait mode
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
            fontSize: 22,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF23234A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.white54),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF7C3AED),
          elevation: 8,
        ),
      ),
      home: SplashScreen(),
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

  @override
  void initState() {
    super.initState();
    chats = demoUsers.map((user) => Chat(user: user, messages: [
      Message(
        text: 'Hello from ${user.name}!',
        sender: user.name,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      ),
      Message(
        text: 'Hi ${user.name}, this is Me!',
        sender: me.name,
        timestamp: DateTime.now().subtract(Duration(minutes: 4)),
      ),
    ])).toList();
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
          sender: 'Me',
          timestamp: DateTime.now(),
        ),
      ]);
      updateChat(updatedChat);
    }
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
          ),
          body: ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => SizedBox(height: 10),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final lastMsg = chat.messages.isNotEmpty ? chat.messages.last : null;
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
                  color: Color(0xFF23234A).withOpacity(0.95),
                  elevation: 6,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF7C3AED),
                      child: Text(chat.user.avatar, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(chat.user.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: lastMsg != null ? Text(
                      lastMsg.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70),
                    ) : null,
                    trailing: lastMsg != null ? Text(
                      '${lastMsg.timestamp.hour.toString().padLeft(2, '0')}:${lastMsg.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ) : null,
                    onTap: () async {
                      final updatedChat = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chat: chat,
                            me: me,
                            onOtherUserMessage: (fromUser, message) {
                              if (fromUser.name != chat.user.name) {
                                _showInAppNotification(context, fromUser, message, (replyText) => _handleSendReply(fromUser.name, replyText));
                              }
                            },
                          ),
                        ),
                      );
                      if (updatedChat != null) {
                        setState(() {
                          chats[index] = updatedChat;
                        });
                      }
                    },
                  ),
                ),
              );
            },
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
                  if (newContact != null && newContact.name.trim().isNotEmpty) {
                    setState(() {
                      chats.add(
                        Chat(
                          user: UserProfile(
                            name: newContact.name.trim(),
                            avatar: newContact.avatar.trim().isNotEmpty ? newContact.avatar.trim() : newContact.name.trim()[0].toUpperCase(),
                          ),
                          messages: [],
                        ),
                      );
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showInAppNotification(BuildContext context, UserProfile fromUser, String message, void Function(String replyText) onSendReply) {
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
            final chat = chats.firstWhere((c) => c.user.name == fromUser.name);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chat: chat,
                  me: me,
                  onOtherUserMessage: (fromUser, message) {
                    if (fromUser.name != chat.user.name) {
                      _showInAppNotification(context, fromUser, message, onSendReply);
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
  final UserProfile me;
  final void Function(UserProfile fromUser, String message)? onOtherUserMessage;
  ChatScreen({required this.chat, required this.me, this.onOtherUserMessage});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Message> _messages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentSender = 'Me';

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.chat.messages);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        Message(
          text: text,
          sender: _currentSender,
          timestamp: DateTime.now(),
        ),
      );
    });
    _controller.clear();
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _simulateOtherUserMessage() {
    // Simulate Bob sending a message while chatting with Alice
    final otherUser = demoUsers.firstWhere((u) => u.name != widget.chat.user.name);
    final msgText = 'Hey! This is a new message from ${otherUser.name}.';
    widget.onOtherUserMessage?.call(otherUser, msgText);
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
              SizedBox(width: 38),
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(20),
                  fillColor: Color(0xFF7C3AED),
                  selectedColor: Colors.white,
                  color: Colors.white70,
                  constraints: BoxConstraints(minWidth: 48, minHeight: 36),
                  isSelected: [ _currentSender == 'Me', _currentSender == widget.chat.user.name ],
                  onPressed: (index) {
                    setState(() {
                      _currentSender = index == 0 ? 'Me' : widget.chat.user.name;
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Me'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(widget.chat.user.name),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg.sender == 'Me';
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
          floatingActionButton: widget.chat.user.name == 'Alice'
              ? FloatingActionButton.extended(
            backgroundColor: Color(0xFF7C3AED),
            icon: Icon(Icons.mail, color: Colors.white),
            label: Text('Simulate Bob', style: TextStyle(color: Colors.white)),
            onPressed: _simulateOtherUserMessage,
          )
              : null,
        ),
      ],
    );
  }
}

// Add dialog and data class for new contact
class _NewContactData {
  final String name;
  final String avatar;
  _NewContactData(this.name, this.avatar);
}

class _AddContactDialog extends StatefulWidget {
  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();

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
            Navigator.of(context).pop(_NewContactData(_nameController.text, _avatarController.text));
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
