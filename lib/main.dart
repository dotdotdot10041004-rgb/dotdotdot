import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

void main() {
  runApp(const DotDotDotApp());
}

class DotDotDotApp extends StatelessWidget {
  const DotDotDotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'dot dot dot',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Pretendard',
      ),
      home: const SplashScreen(),
    );
  }
}

class AppColors {
  static const bg = Color(0xFF121212);
  static const card = Color(0xFF666A6A);
  static const myBubble = Color(0xFFF3B0D2);
  static const otherBubble = Color(0xFFF7F7F7);
  static const neon = Color(0xFFFF4FA3);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: BrandLogo(size: 170)),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();

  Future<void> _askEnter() async {
    final nick = _controller.text.trim();
    if (nick.isEmpty || nick.length > 10) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: const Text('입장 확인'),
        content: Text('닉네임 "$nick"으로 입장할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LobbyScreen(nickname: nick)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandLogo(size: 170),
                const SizedBox(height: 44),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _askEnter(),
                    maxLength: 10,
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '닉네임을 입력해주세요',
                      hintStyle: const TextStyle(color: Colors.white70),
                      fillColor: AppColors.card,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key, required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandLogo(size: 100),
                const SizedBox(height: 26),
                ...List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: RoomButton(
                      label: 'ROOM ${i + 1}',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            nickname: nickname,
                            roomId: 'room_${i + 1}',
                            roomName: 'ROOM ${i + 1}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.nickname,
    required this.roomId,
    required this.roomName,
  });

  final String nickname;
  final String roomId;
  final String roomName;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _scroll = ScrollController();
  final _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  io.Socket? _socket;
  bool _isOtherTyping = false;
  bool _connected = false;
  String _socketLog = '';
  Timer? _typingOffTimer;

  String get _socketUrl {
    const envUrl = String.fromEnvironment('SOCKET_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    // 요청값 기본 반영 (개발 중 고정 서버 IP)
    return 'http://192.168.0.154:3001';
  }

  void _logSocket(String msg) {
    debugPrint(msg);
    if (mounted) {
      setState(() => _socketLog = msg);
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _connectSocket();
  }

  void _connectSocket() {
    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setTimeout(5000)
          .setQuery({'nickname': widget.nickname})
          .build(),
    );

    _logSocket('[socket] trying: $_socketUrl room=${widget.roomId} nick=${widget.nickname}');

    _socket!.onConnect((_) {
      _logSocket('[socket] connected: id=${_socket!.id} url=$_socketUrl');
      if (mounted) setState(() => _connected = true);
      _socket!.emit('join_room', {
        'roomId': widget.roomId,
        'nickname': widget.nickname,
      });
    });

    _socket!.onDisconnect((reason) {
      _logSocket('[socket] disconnected: reason=$reason url=$_socketUrl');
      if (mounted) setState(() => _connected = false);
    });

    _socket!.onConnectError((err) {
      _logSocket('[socket] connect_error: $err url=$_socketUrl');
      if (mounted) setState(() => _connected = false);
    });

    _socket!.onError((err) {
      _logSocket('[socket] error: $err');
    });

    _socket!.on('new_message', (data) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.fromMap(data as Map));
      });
      _scrollToBottom();
    });

    _socket!.on('typing', (data) {
      if (!mounted) return;
      final map = data as Map;
      final from = map['nickname']?.toString() ?? '';
      if (from == widget.nickname) return;
      setState(() => _isOtherTyping = (map['typing'] == true));
    });

    _socket!.connect();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_socket == null || !_connected) {
      // 서버 미연결 시에도 UI 확인 가능하도록 로컬 반영
      setState(() {
        _messages.add(
          ChatMessage(
            nickname: widget.nickname,
            text: text,
            createdAt: DateTime.now(),
          ),
        );
      });
      _controller.clear();
      _scrollToBottom();
      return;
    }

    _socket!.emit('send_message', {
      'roomId': widget.roomId,
      'nickname': widget.nickname,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    });

    _controller.clear();
    _sendTyping(false);
  }

  void _sendTyping(bool typing) {
    if (_socket == null) return;
    _socket!.emit('typing', {
      'roomId': widget.roomId,
      'nickname': widget.nickname,
      'typing': typing,
    });
  }

  Future<void> _leaveRoom() async {
    _socket?.emit('leave_room', {
      'roomId': widget.roomId,
      'nickname': widget.nickname,
    });
    setState(() {
      _messages.clear(); // 클라이언트 사이드 대화 로그 초기화
      _isOtherTyping = false;
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _typingOffTimer?.cancel();
    _sendTyping(false);
    _socket?.disconnect();
    _socket?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.roomName, style: const TextStyle(color: Colors.black)),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _connected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD0D0D0),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _leaveRoom,
            icon: const Icon(Icons.logout_rounded),
            tooltip: '나가기',
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              '(오늘) ${TimeOfDay.now().format(context)}',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            if (!_connected && _socketLog.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _socketLog,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final msg = _messages[i];
                  return MessageBubble(
                    message: msg,
                    mine: msg.nickname == widget.nickname,
                  );
                },
              ),
            ),
            if (_isOtherTyping)
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TypingDots(),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 18,
                top: 6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) {
                        _sendTyping(v.isNotEmpty);
                        _typingOffTimer?.cancel();
                        _typingOffTimer =
                            Timer(const Duration(milliseconds: 1200), () {
                          _sendTyping(false);
                        });
                      },
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: '메시지 입력',
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.neon,
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomButton extends StatelessWidget {
  const RoomButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(label, style: const TextStyle(fontSize: 34 * 0.55)),
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.screen),
        child: Image.asset('assets/images/logo.jpg', fit: BoxFit.contain),
      ),
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.nickname,
    required this.text,
    required this.createdAt,
  });

  final String nickname;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromMap(Map map) {
    return ChatMessage(
      nickname: map['nickname']?.toString() ?? 'unknown',
      text: map['text']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.nickname,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.myBubble : AppColors.otherBubble,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(color: mine ? Colors.black : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.otherBubble,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = ((t - i * 0.15) % 1.0);
              final scale = 0.6 + (phase < 0.5 ? phase : 1 - phase) * 1.2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: const CircleAvatar(radius: 3, backgroundColor: Colors.black54),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
