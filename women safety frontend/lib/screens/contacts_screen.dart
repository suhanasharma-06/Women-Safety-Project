import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../models/contact.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> contacts = [];
  bool loading = false;
  String? token;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  _loadContacts() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");

    if (token != null) {
      try {
        contacts = await ApiService.getContacts(token!);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    setState(() => loading = false);
  }

  _addContact() async {
    if (token == null) return;

    Contact c = await ApiService.addContact(
      token!,
      _name.text.trim(),
      _phone.text.trim(),
      _relation.text.trim(),
    );

    _name.clear();
    _phone.clear();
    _relation.clear();

    setState(() => contacts.insert(0, c));
  }

  _deleteContact(String id) async {
    if (token == null) return;

    await ApiService.deleteContact(token!, id);

    setState(() => contacts.removeWhere((c) => c.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: Colors.pink,
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // INPUT FIELDS
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(hintText: "Name"),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _phone,
                    decoration: const InputDecoration(hintText: "Phone"),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _relation,
                    decoration: const InputDecoration(hintText: "Relation"),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: _addContact,
                  child: const Text("Add"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CONTACT LIST
            loading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: contacts.isEmpty
                        ? const Center(child: Text("No contacts added"))
                        : ListView.builder(
                            itemCount: contacts.length,
                            itemBuilder: (context, i) {
                              final c = contacts[i];

                              return Card(
                                elevation: 2,
                                child: ListTile(
                                  title: Text(c.name),
                                  subtitle: Text(
                                      "${c.phone}  ${c.relation == null ? '' : '• ${c.relation!}'}"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteContact(c.id),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
