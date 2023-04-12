import 'package:appwrite/appwrite.dart';
import 'package:appwrite_app/appwrite/auth_api.dart';
import 'package:appwrite_app/appwrite/database_api.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as model;
import 'package:provider/provider.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final database = DatabaseAPI();
  late List<model.Document>? messages = [];
  TextEditingController messageTextController = TextEditingController();
  AuthStatus authStatus = AuthStatus.uninitialized;

  @override
  void initState() {
    super.initState();
    final AuthAPI appwrite = context.read<AuthAPI>();
    authStatus = appwrite.status;
    loadMessages();
  }

  loadMessages() async {
    try {
      final value = await database.getMessages();
      setState(() {
        messages = value.documents;
      });
    } catch (e) {
      print(e);
    }
  }

  addMessage() async {
    try {
      await database.addMessage(message: messageTextController.text);
      const snackbar = SnackBar(content: Text('Message added!'));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
      messageTextController.clear();
      loadMessages();
    } on AppwriteException catch (e) {
      showAlert(title: 'Error', text: e.message.toString());
    }
  }

  deleteMessage(String id) async {
    try {
      await database.deleteMessage(id: id);
      loadMessages();
    } on AppwriteException catch (e) {
      showAlert(title: 'Error', text: e.message.toString());
    }
  }

  showAlert({required String title, required String text}) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(text),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Ok'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                authStatus == AuthStatus.authenticated
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageTextController,
                              decoration: const InputDecoration(
                                  hintText: 'Type a message'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                              onPressed: () {
                                addMessage();
                              },
                              icon: const Icon(Icons.send),
                              label: const Text("Send")),
                        ],
                      )
                    : const Center(),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                      itemCount: messages?.length ?? 0,
                      itemBuilder: (context, index) {
                        final message = messages![index];
                        return Card(
                            child: ListTile(
                          title: Text(message.data['text']),
                          trailing: IconButton(
                              onPressed: () {
                                deleteMessage(message.$id);
                              },
                              icon: const Icon(Icons.delete)),
                        ));
                      }),
                )
              ]),
        ),
      ),
    );
  }
}
