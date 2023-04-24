import 'dart:async';

import 'package:flutter/material.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() => runApp(MyApp());

// STEP1:  Stream setup
class StreamSocket {
  final _socketResponse = StreamController<String>();

  void Function(String) get addResponse => _socketResponse.sink.add;

  Stream<String> get getResponse => _socketResponse.stream;

  void dispose() {
    _socketResponse.close();
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'DEMO APP';
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: title,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  IO.Socket? _socket;
  final myController = TextEditingController();
  bool _isloading = false;
  bool _isSending = false;

  // STEP2:  Stream setup
  StreamSocket streamSocket = StreamSocket();

  final spinkit = SpinKitFadingCircle(
    color: Colors.blue,
    size: 30.0,
  );

  final sendKit=SpinKitFadingGrid(
    color: Colors.blue,
    size: 25.0,
  );
  @override
  void initState() {
    // TODO: implement initState
    initSocket();
    // initStreamBuilder();
    // initStream();
    super.initState();
  }

  void initSocket() {
    try {
      _socket = IO.io('http://192.168.159.72:3010', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket?.connect();

      _socket?.onConnect((_) {
        print('connect to server succesfully');
        // _socket?.emit("gotoserver",myController.text);
      });

      _socket?.on("goToMobile", (data) {
        //waiting for data for 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            _isloading = true;
          });
        }); 

        streamSocket.addResponse(data);
        _isloading = false;
      });

      _socket?.onDisconnect((_) {
        print('disconnect to server');
      });
    } catch (err) {
      print(err);
    }
  }

  void sendText(String msg) {
    _socket?.emit("gotoserver", msg);
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isSending = true;
      });
    });
    setState(() {
      _isSending = false;
    });
    //empty text field
    myController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
                child: TextField(
              controller: myController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your message',
              ),
            )),
            
            SizedBox(height: 24),
            _isSending
                ? sendKit
                :SizedBox(height: 20),
            // spinkit,
            // STEP3:  Stream setup
            Text(
              " data recieved from pico: ",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 24),
            _isloading
                ? spinkit
                :
          

            StreamBuilder<String>(
              stream: streamSocket.getResponse,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data!,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue,
                      decorationStyle: TextDecorationStyle.dashed,
                    ),
                    // ),
                  );
                } else {
                  return Text('No data');
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          sendText(myController.text);
        },
        tooltip: 'Send message',
        child: Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  // void _sendMessage() {
  //   if (_controller.text.isNotEmpty) {
  //     _channel.sink.add(_controller.text);
  //     _controller.text= '';
  //   }
  // }

  @override
  void dispose() {
    // _channel.sink.close();
    // _controller.dispose();
    myController.dispose();
    // _streamController.close();

    super.dispose();
  }
}
