import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:username_gen/username_gen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';

int ADD_CONTACT=5;
int ITEM_PER_PAGE=15;

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
      title: 'Khaw Teng Xian',
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
      home: const MyHomePage(title: 'Khaw Teng Xian'),
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
  ScrollController _scrollController = new ScrollController();
  List<bool> isSelected=[true,false];
  bool isTimeAgo=true;

  @override
  void initState(){

    get_contact();
    isTimeAgo=getTimeAgo() as bool;
    super.initState();
  }

  @override
  void dispose() {
    // disposing states
    savedInstanceState_contact=[];
    super.dispose();
  }
  
  void get_contact()async{
    savedInstanceState_contact= await fetchContact();
  }
  void savePreference(bool s) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timeAgo',s);
  }
  Future<bool> getTimeAgo()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool timeAgo = await prefs.getBool('timeAgo') ?? true;
    return timeAgo;
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
        actions: [ToggleButtons(children: <Widget>[Icon(Icons.alarm,color: Colors.white),
          Icon(Icons.date_range,color:Colors.white,),
        ],onPressed:(index){


          setState(() {
            savePreference(isSelected[index]);
            isTimeAgo=isSelected[index];
          });
        },isSelected: isSelected, )],
      ),
      body: RefreshIndicator(
            child: ListView.builder(
                itemCount: savedInstanceState_contact.length ,
              itemBuilder: (context, index){

//find the index
                if(isTimeAgo==false){
                  return ListTile(
                    leading: Text(savedInstanceState_contact.elementAt(index).user),
                    title: Text(savedInstanceState_contact.elementAt(index).phone),
                    trailing: Text(savedInstanceState_contact.elementAt(index).checkIn),
                  );
                }else {
                  //Duration diff = DateTime.now().difference(DateTime.parse(savedInstanceState_contact.elementAt(index).checkIn));
                  //DateTime.now().subtract(diff);

                  return ListTile(
                    leading: Text(savedInstanceState_contact.elementAt(index).user),
                    title: Text(savedInstanceState_contact.elementAt(index).phone),
                    trailing: Text(timeago.format(DateTime.parse(savedInstanceState_contact.elementAt(index).checkIn))),
                  );
                }

              },

              //let the screen display 15 contacts maximum at a time
             reverse: true,
              physics: const AlwaysScrollableScrollPhysics(),
            ),

      onRefresh:(){
        String randomDate;
        String phoneNo;
        String uname;
        List<Contact> listContact=[];

        for (var i=0 ;i<ADD_CONTACT;i++){

          randomDate= DateTime.now().toString().substring(0,10) +" "+ DateFormat.Hms().format(DateTime.now());
          phoneNo="01"+Random().nextInt(99999999).toString();
          uname=UsernameGen().generate();

          Contact c = new Contact(checkIn:randomDate, phone:phoneNo, user: uname);
          listContact.add(c);

        }

        return Future.delayed(Duration(seconds: 0),
                (){
              setState(() {
                savedInstanceState_contact.addAll(listContact);

                //savedInstanceState_contact;
              });
              Fluttertoast.showToast(
                  msg: "Page Refreshed",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.blueGrey,
                  textColor: Colors.white,
                  fontSize: 16.0
              );
            }
        );
      }
      ),

    );
  }
}

