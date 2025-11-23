import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';
import '../state/store.dart';
import '../bridge_generated.dart';

class ContactPicker extends ConsumerWidget {
  const ContactPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF15151F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text("SELECT CONTACT", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 16),
          Expanded(
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text("Error: $err"),
              data: (contacts) {
                if (contacts.isEmpty) {
                  return Center(child: Text("No contacts saved.", style: TextStyle(color: Colors.white.withOpacity(0.3))));
                }
                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: const Color(0xFF1A1A24), child: Text(contact.alias[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                      title: Text(contact.alias, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("${contact.pubkey.substring(0, 12)}...", style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'monospace')),
                      onTap: () => Navigator.pop(context, contact.pubkey),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
