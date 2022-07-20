import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:username_gen/username_gen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

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
        primarySwatch: Colors.blueGrey,
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
  bool isTimeAgo=true,sharing=false;
  String share_name='',
       share_phoneNo='',
  share_time='';

  @override
  void initState(){

    get_contact();
    setTimeAgo();
    _scrollController.addListener(() {
      if(_scrollController.position.pixels==0 && _scrollController.position.atEdge) {
        // print(_scrollController.position.pixels!=0 && _scrollController.position.atEdge);
        Fluttertoast.showToast(
            msg: "You have reached to the end of the list",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.blueGrey,
            textColor: Colors.white,
            fontSize: 16.0
        );

      }
    });
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
    savedInstanceState_contact.sort((a, b) => DateTime.parse(a.checkIn).compareTo(DateTime.parse(b.checkIn)));
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
  void setTimeAgo()async{
    isTimeAgo=await getTimeAgo();
  }
  void _onShare(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(share_name,
        subject: share_phoneNo+ "\n"+share_time,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: !sharing?AppBar(title: Text(widget.title),
        actions: [ToggleButtons(children: <Widget>[
          Card(color: isTimeAgo?Colors.amberAccent:Colors.blueGrey,
            child:Icon(Icons.alarm,color: Colors.white,),),
      Card(color: !isTimeAgo?Colors.amberAccent:Colors.blueGrey,
          child:Icon(Icons.date_range,color:Colors.white,),)],onPressed:(index){
          setState(() {
            savePreference(isSelected[index]);
            isTimeAgo=isSelected[index];

          });
        },isSelected: isSelected, )
    ],):AppBar(
leading:IconButton(onPressed:() {
  setState(() {
    sharing=false;
  });
}, icon: Icon(Icons.arrow_back),
) ,
        actions: [
          IconButton(onPressed:() {
          _onShare(context);
        }, icon: Icon(Icons.share),
        )],
      ),
      body:RefreshIndicator(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: savedInstanceState_contact.length ,
            itemBuilder: (context, index){

//find the index
              if(isTimeAgo==false){
                return Card(child:  GestureDetector(child: ListTile(
                  leading: Text(savedInstanceState_contact.elementAt(index).user),
                  title: Text(savedInstanceState_contact.elementAt(index).phone),
                  trailing: Text(savedInstanceState_contact.elementAt(index).checkIn),
                ),onLongPress: (){
                  share_name=savedInstanceState_contact.elementAt(index).user;
                  share_phoneNo=savedInstanceState_contact.elementAt(index).phone;
                  share_time=savedInstanceState_contact.elementAt(index).checkIn;
                  setState(() {
                    sharing=true;
                  });
                },),);
              }else {
                //Duration diff = DateTime.now().difference(DateTime.parse(savedInstanceState_contact.elementAt(index).checkIn));
                //DateTime.now().subtract(diff);

                return Card(child:GestureDetector(child: ListTile(
                  leading: Text(savedInstanceState_contact.elementAt(index).user),
                  title: Text(savedInstanceState_contact.elementAt(index).phone),
                  trailing: Text(timeago.format(DateTime.parse(savedInstanceState_contact.elementAt(index).checkIn))),
                ),onLongPress: (){
                  share_name=savedInstanceState_contact.elementAt(index).user;
                  share_phoneNo=savedInstanceState_contact.elementAt(index).phone;
                  share_time=savedInstanceState_contact.elementAt(index).checkIn;

                  setState(() {
                   sharing=true;
                  });

                },) ,);
              }

            },

            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
          ),


          onRefresh:(){
            String randomDate;
            String phoneNo;
            String uname;
            List<Contact> listContact=[];

            for (var i=0 ;i<ADD_CONTACT;i++){

              randomDate= DateTime.now().subtract(Duration(days: Random().nextInt(365))).toString().substring(0,10) +" "+
                  DateFormat.Hms().format(DateTime.now().subtract(Duration(hours:Random().nextInt(24),minutes: Random().nextInt(60))));
              phoneNo="01"+Random().nextInt(99999999).toString();
              uname=UsernameGen().generate();

              Contact c = new Contact(checkIn:randomDate, phone:phoneNo, user: uname);
              listContact.add(c);

            }

            return Future.delayed(Duration(seconds: 0),
                    (){
                  setState(() {
                    savedInstanceState_contact.addAll(listContact);
                    savedInstanceState_contact.sort((a, b) => DateTime.parse(a.checkIn).compareTo(DateTime.parse(b.checkIn)));
                    //savedInstanceState_contact;
                  });
                  Fluttertoast.showToast(
                      msg: "Page Refreshed\n5 random contacts added",
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

