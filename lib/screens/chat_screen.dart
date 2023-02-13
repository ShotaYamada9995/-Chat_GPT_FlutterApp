import 'package:chatgpt_app/constants/constants.dart';
import 'package:chatgpt_app/screens/keyGenerate_screen.dart';
import 'package:chatgpt_app/services/api_services.dart';
import 'package:chatgpt_app/services/assets_manager.dart';
import 'package:chatgpt_app/widgets/chat_widget.dart';
import 'package:chatgpt_app/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:chatgpt_app/services/assets_manager.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:developer';
import 'package:chatgpt_app/services/services.dart';
import 'package:provider/provider.dart';

import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/models_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  
  bool isTyping = false;
  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;

  @override
  void initState(){
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose(){
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  //List<ChatModel> chatList = [];
  @override
  Widget build(BuildContext context) {
    final modelsProvider = Provider.of<ModelsProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: Colors.white,
        elevation: 2,
        // leading: Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: Image.asset('images/openai_logo.jpg'),
        // ),
        title: const Text("ChatGPT"),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18.0
        ),
        iconTheme: IconThemeData(color: Colors.black87),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     onPressed: () async {
        //       await Services.showModalSheet(context: context);
        //     },
        //     icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
        //   ),
        // ],
      ),
      drawer: NavigationDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              Flexible(
                child: ListView.builder(
                    controller: _listScrollController,
                    itemCount: chatProvider.getChatList.length, //chatList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: ChatWidget(
                          msg: chatProvider
                              .getChatList[index].msg, // chatList[index].msg,
                          chatIndex: chatProvider.getChatList[index]
                              .chatIndex, //chatList[index].chatIndex,
                        ),
                      );
                    }),
              ),
              if (isTyping) ...[
                const SpinKitThreeBounce(
                  color: Colors.black,
                  size: 18,
                ),
              ],
              const SizedBox(
                height: 15,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Colors.green,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  color: cardcolor,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: focusNode,
                            style: const TextStyle(color: Colors.black),
                            controller: textEditingController,
                            onSubmitted: (value) async {
                              await sendMessageFCT(
                                  modelsProvider: modelsProvider,
                                  chatProvider: chatProvider);
                            },
                            decoration: const InputDecoration.collapsed(
                                hintText: "How can I help you",
                                hintStyle: TextStyle(color: Colors.grey)
                            ),
                          ),
                        ),
                        IconButton(
                            onPressed: () async {
                              await sendMessageFCT(
                                  modelsProvider: modelsProvider,
                                  chatProvider: chatProvider);
                            },
                            icon:  Transform.rotate(
                              angle: 320,
                              child: Icon(
                                Icons.send,
                                color: Colors.black87,
                              ),
                            ))
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Free Research Preview. Our goal is to make AI systems more natural and safe to interact with. Your feedback will help us improve.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void scrollListToEND() {
    _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.easeOut);
  }

  Future<void> sendMessageFCT(
      {required ModelsProvider modelsProvider,
        required ChatProvider chatProvider}) async {
    if (isTyping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "You cant send multiple messages at a time",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (textEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "Please type a message",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      String msg = textEditingController.text;
      setState(() {
        isTyping = true;
        // chatList.add(ChatModel(msg: textEditingController.text, chatIndex: 0));
        chatProvider.addUserMessage(msg: msg);
        textEditingController.clear();
        focusNode.unfocus();
      });
      await chatProvider.sendMessageAndGetAnswers(
          msg: msg, chosenModelId: modelsProvider.getCurrentModel);
      // chatList.addAll(await ApiService.sendMessage(
      //   message: textEditingController.text,
      //   modelId: modelsProvider.getCurrentModel,
      // ));
      setState(() {});
    } catch (error) {
      log("error $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TextWidget(
          label: error.toString(),
        ),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        scrollListToEND();
        isTyping = false;
      });
    }
  }
}

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Drawer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            buildHeader(context),
            buildMenuItems(context),
          ],
        ),
      ),
    );
  }
  Widget buildHeader(BuildContext context) => Container(
    padding: EdgeInsets.all(24.0),
    child: Wrap(
      runSpacing: 20.0,
    ),
  );
  Widget buildMenuItems(BuildContext context) => Column(
    children: [
      ListTile(
        leading: Icon(Icons.chat_sharp),
        title: Text('Chat with me'),
        onTap: () {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => ChatScreen()));
        },
      ),
      ListTile(
        leading: Icon(Icons.key_outlined),
        title: Text('Generate a Key'),
        onTap: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => GenerateKey())
          );
        },
      ),
      ListTile(
        leading: Icon(Icons.home_outlined),
        title: Text('Home'),
        onTap: () {},
      ),
      Divider(color: Colors.black54),
      ListTile(
        leading: Icon(Icons.home_outlined),
        title: Text('Home'),
        onTap: () {},
      ),
      ListTile(
        leading: Icon(Icons.home_outlined),
        title: Text('Home'),
        onTap: () {},
      ),
    ],
  );
}



