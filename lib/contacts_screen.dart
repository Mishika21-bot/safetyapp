import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<String> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() async {
    final doc = await firestore.collection('user_data').doc('contacts').get();
    if (doc.exists) {
      setState(() {
        contacts = List<String>.from(doc.data()!['numbers']);
      });
    }
  }

  void _addContact() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        contacts.add(_controller.text);
        _controller.clear();
      });
      await firestore.collection('user_data').doc('contacts').set({
        'numbers': contacts,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trusted Contacts")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Enter phone number",
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addContact,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(contacts[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      contacts.removeAt(index);
                    });
                    firestore.collection('user_data').doc('contacts').set({
                      'numbers': contacts,
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}