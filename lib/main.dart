import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future <List<Contact>> fetchContact() async{
  final response = await http.get(Uri.parse('http://tengxian.pythonanywhere.com/'));
  print("The response is ");
  print(response);
  var json_contact=json.decode(response.body);
  List <Contact> contact_list=[];

  if(response.statusCode==200){
    for(var j in json_contact){
  print(j['check-in']);
  Contact contact=new Contact(checkIn: j['check-in'], phone: j['phone'], user: j['user']);
contact_list.add(contact);
    }
    return contact_list;
  }
  else{
    throw Exception('Failed to load contact list');
  }
}

class Contact{
  final String checkIn;
  final String phone;
  final String user;

  const Contact({
    required this.checkIn,
    required this.phone,
    required this.user,
  });

  factory Contact.fromJson(Map<String,dynamic> json)
  {
    return Contact(checkIn: json['check-in'],
      phone: json['phone'],
      user: json['user'],);
  }

}


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Assessment Khaw Teng Xian',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Assessment Khaw Teng Xian'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List <Contact> savedInstanceState_contact=[];
  void get_contact()async{
    savedInstanceState_contact= await fetchContact();
  }
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }
  void _append_contact(){
    fetchContact();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
child:FutureBuilder<List<Contact>>(
  future: fetchContact(),
  builder: (context,AsyncSnapshot snapshot){
    if(snapshot.hasData){
      return Container(child: ListView.builder(
        itemCount: (snapshot.data?.length <15) ? snapshot.data?.length :15,
          itemBuilder:(BuildContext context, int index){
          print('snapshot length is ');
          print(snapshot.data?.length);
        return Text(snapshot.data[index].user);

      },),);
    }
    else if(snapshot.hasError){
      return Text('${snapshot.error}');
    }
    return const CircularProgressIndicator();
  },
) ,
      onRefresh:(){ return Future.delayed(Duration(seconds: 1),
          (){
        setState(() {

        });
          }
        );
    }
    ));
  }
}

