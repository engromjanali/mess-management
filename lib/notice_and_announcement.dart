import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mess_management/add_notice.dart';
import 'package:mess_management/constants.dart';
import 'package:mess_management/helper/helper_method.dart';
import 'package:mess_management/helper/ui_helper.dart';
import 'package:mess_management/model/notice_model.dart';
import 'package:mess_management/providers/authantication_provider.dart';
import 'package:mess_management/providers/mess_provider.dart';
import 'package:mess_management/providers/notice_provider.dart';
import 'package:provider/provider.dart';

class NoticeAndAnnouncementScreen extends StatefulWidget {
  const NoticeAndAnnouncementScreen({super.key});

  @override
  State<NoticeAndAnnouncementScreen> createState() => _NoticeAndAnnouncementScreenState();
}

class _NoticeAndAnnouncementScreenState extends State<NoticeAndAnnouncementScreen> {
  // double posX = -50;
  // double posY = -50;
  ScrollController  _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    // Delay getting screen size until layout is built
    WidgetsBinding.instance.addPostFrameCallback((_)async {
      await Future.delayed(Duration(milliseconds: 100));
      final size = MediaQuery.of(context).size;
      // setState(() {
      //   posX = (size.width - 56) / 2; // Center horizontally (56 = FAB size)
      //   posY = size.height - 200; // Near bottom (adjust for AppBar & padding)
      // });
      final noticeProvider = context.read<NoticeProvider>();
      final authProvaider = context.read<AuthenticationProvider>();
      noticeProvider.loadInitial(messId: authProvaider.getUserModel!.currentMessId, uId: authProvaider.getUserModel!.uId);
      noticeProvider.listenToNotice(messId: authProvaider.getUserModel!.currentMessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final noticeProvider = context.watch<NoticeProvider>();
    final messProvider = context.read<MessProvider>();
    final authProvider = context.read<AuthenticationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Notices"),
        backgroundColor: Colors.grey,
        actions: [
          IconButton(
            onPressed: () {
              if(!(amIAdmin(messProvider: messProvider, authProvider: authProvider) || amIactmenager(messProvider: messProvider, authProvider: authProvider))){
                showSnackber(context: context, content: "Required Administrator Power");
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (context)=>AddNotice()));
            },
            icon: Icon(Icons.add, color: Colors.black, size: 35,)
          ),
        ],
      ),
      body:SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (noticeProvider.isLoading) 
              Center(child: showCircularProgressIndicator()),
            if (noticeProvider.getNoticeList == null || noticeProvider.getNoticeList.isEmpty) 
              Center(child: Text('No Data Found')),
              // return Text("sdf");
               ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: noticeProvider.getNoticeList.length,
                itemBuilder: (context, index) {
                  bool showDesc = false;
                  NoticeModel noticeModel = noticeProvider.getNoticeList[index];
                  return StatefulBuilder(
                    builder: (context, setLocalState) {
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              
                              contentPadding: EdgeInsets.only(left: 8),
                              onTap: () {
                                setLocalState((){
                                  showDesc = !showDesc;
                                });
                              },
                              leading: CircleAvatar(
                                backgroundColor: Colors.red,
                              ),
                              title: Text(noticeModel.title.toString()),
                              subtitle: Text(DateFormat("hh:mm a dd-MM-yyyy").format(noticeModel.CreatedAt!.toDate().toLocal())),
                              trailing: PopupMenuButton(
                                offset: Offset.fromDirection(1),
                                icon: Icon(Icons.more_vert),
                                itemBuilder: (context) =>[
                                  PopupMenuItem(
                                    value: 0,
                                    child: ListTile(
                                      title: Text("Pin To Home",style : getTextStyleForTitleS()),
                                      leading: Icon(Icons.push_pin_sharp,),
                                    ), 
                                    onTap: () {
                                      if(!(amIAdmin(messProvider: messProvider, authProvider: authProvider) || amIactmenager(messProvider: messProvider, authProvider: authProvider))){
                                        showSnackber(context: context, content: "Required Administrator Power");
                                        return;
                                      }
                                      noticeProvider.pinToHome(
                                        noticeModel: noticeModel, 
                                        messId: authProvider.getUserModel!.currentMessId,
                                        onFail: (p0) {
                                          showSnackber(context: context, content: "Action Failed!\n$p0");
                                        },
                                        onSuccess: (){
                                          showSnackber(context: context, content: "Pinded, Look AT Home.");
                                        }
                                      );
                                    },
                                  ),
                                  PopupMenuItem(
                                    value: 1,
                                    child: ListTile(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        if(!(amIAdmin(messProvider: messProvider, authProvider: authProvider) || amIactmenager(messProvider: messProvider, authProvider: authProvider))){
                                          showSnackber(context: context, content: "Required Administrator Power");
                                          return;
                                        }
                                        Navigator.push(context, MaterialPageRoute(builder: (context)=>AddNotice(preNoticeModel: noticeModel,)));
                                      },
                                      title: Text("Edit",style : getTextStyleForTitleS()),
                                      leading: Icon(Icons.edit, color: Colors.green,),
                                    ), 
        
                                  ),
                        
                                  PopupMenuItem(
                                    value: 2,
                                    // onTap: (){
                                    //   // if i use this function. we don't need to Navigator.pop()
                                    // },
                                    child: ListTile(
                                      title: Text("Delete",style : getTextStyleForTitleS()),
                                      leading: Icon(Icons.delete, color: Colors.red,),
                                      onTap: ()async{
                                        Navigator.pop(context); // if i use this function. we have to Navigator.pop() for close listview and can't called parent/PopupMenuItem's ontap function
                                        if(!(amIAdmin(messProvider: messProvider, authProvider: authProvider) || amIactmenager(messProvider: messProvider, authProvider: authProvider))){
                                          showSnackber(context: context, content: "Required Administrator Power");
                                          return;
                                        }
                                        bool? confirm = await showDialog(context: context, builder: (content)=>AlertDialog(
                                          title: Text("Do you want to delete?",style : getTextStyleForTitleM()),
                                          actionsAlignment: MainAxisAlignment.start,
                                          actions: [
                                            TextButton(child: Text("No"), onPressed: (){
                                              Navigator.pop(context, false);
                                            },),
                                            TextButton(child: Text("Yes") , onPressed: (){
                                            Navigator.pop(context, true);
                                            },),
                                          ],
                                        ));
                                        if(confirm!=null && confirm){
                                          debugPrint("Confirmed ------------");
                                          await noticeProvider.deleteANotice(
                                            messId: authProvider.getUserModel!.currentMessId, 
                                            noticeId: noticeModel.noticeId, 
                                            onFail: (message ) {
                                              print("failed");
                                              showSnackber(context: context, content: "Deletion Failed!\n$message");
                                            },
                                            onSuccess: (){
                                              print("success");
                                              setState(() {
                                                showSnackber(context: context, content: "Deletion Successed.");
                                              });
                                            }
                                          );
                                        }
                                      },
                                    ), 
                                  ),
                                ]
                              ),
                            ),
                      
                            if(showDesc) Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(noticeModel.description),
                            ),
                          ],
                        ),
                      );
                    }
                  );
                }, 
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 20),
                       child: noticeProvider.isLoading? showCircularProgressIndicator() :Row(
                        mainAxisAlignment:(noticeProvider.getHasMoreBackword && noticeProvider.getHasMoreForword)? MainAxisAlignment.spaceBetween:MainAxisAlignment.center,
                        children: [
                           if(noticeProvider.getHasMoreBackword) ElevatedButton(
                             onPressed: (){noticeProvider.loadPrevious(messId: authProvider.getUserModel!.currentMessId).then((_){
                               if(_scrollController.hasClients){
                                 // _scrollController.jumpTo(
                                 //   _scrollController.position.minScrollExtent,
                                 // );
                               }
                               });},
                               child: Text("Prev")
                             ),
                       
                          if(noticeProvider.getHasMoreForword) ElevatedButton(
                            onPressed: (){noticeProvider.loadNext(messId: authProvider.getUserModel!.currentMessId).then((_){
                              if(_scrollController.hasClients){
                                _scrollController.jumpTo(
                                  _scrollController.position.minScrollExtent,
                                );
                              }
                              });},
                              child: Text(  "Next" )
                            ),
                          ]
                        ),
                     ),
                   )
          ],
        ),
      ),
    );
  }
}