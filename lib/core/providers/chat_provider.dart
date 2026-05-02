import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String id;
  final String orderId;
  final String senderRole;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      orderId: map['order_id'] ?? '',
      senderRole: map['sender_role'] ?? 'CUSTOMER',
      content: map['content'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

final chatProvider = StateNotifierProvider.family<ChatNotifier, List<ChatMessage>, String>((ref, orderId) {
  return ChatNotifier(orderId);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final String orderId;
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  ChatNotifier(this.orderId) : super([]) {
    _fetchMessages();
    _subscribe();
  }

  Future<void> _fetchMessages() async {
    final response = await _supabase
        .from('order_messages')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: true);
    
    state = (response as List).map((m) => ChatMessage.fromMap(m)).toList();
  }

  void _subscribe() {
    _channel = _supabase
        .channel('chat_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) {
            final newMessage = ChatMessage.fromMap(payload.newRecord);
            
            // Deduplicate: Don't add if message ID already exists 
            // or if a temporary message with same content exists
            final exists = state.any((m) => 
              m.id == newMessage.id || 
              (m.id.startsWith('temp-') && 
               m.content == newMessage.content && 
               m.senderRole == newMessage.senderRole)
            );

            if (!exists) {
              state = [...state, newMessage];
            } else {
              // Replace temp message with real message to get correct ID and timestamp
              state = state.map((m) => 
                (m.id.startsWith('temp-') && m.content == newMessage.content && m.senderRole == newMessage.senderRole)
                ? newMessage 
                : m
              ).toList();
            }
          },
        )
        .subscribe();
  }

  Future<void> sendMessage(String content) async {
    final newMessage = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      senderRole: 'CUSTOMER',
      content: content,
      createdAt: DateTime.now(),
    );
    
    // Optimistic update
    state = [...state, newMessage];

    try {
      await _supabase.from('order_messages').insert({
        'order_id': orderId,
        'sender_role': 'CUSTOMER',
        'content': content,
      });
    } catch (e) {
      // If error, remove the temp message
      state = state.where((m) => m.id != newMessage.id).toList();
      rethrow;
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
