import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:mess_management/constants.dart';
import 'package:mess_management/helper/helper_method.dart';
import 'package:mess_management/helper/ui_helper.dart';
import 'package:mess_management/model/mess_model.dart';
import 'package:mess_management/providers/authantication_provider.dart';
import 'package:mess_management/providers/mess_provider.dart';
import 'package:provider/provider.dart';

class MessUpdate extends StatefulWidget {
  const MessUpdate({super.key});

  @override
  State<MessUpdate> createState() => _MessUpdateState();
}

class _MessUpdateState extends State<MessUpdate> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool transferOwnership = false;
  TextEditingController messNameController = TextEditingController();
  TextEditingController messAddressController = TextEditingController();
  TextEditingController messOwnerNameController = TextEditingController();
  TextEditingController messOwnerIdController = TextEditingController();
  TextEditingController authorityPhoneController = TextEditingController();
  TextEditingController authorityEmailController = TextEditingController();

  final dropdownKey = GlobalKey<DropdownSearchState>();
  bool _disposed = false;

  List<String > list =["wqer","qwe"];
  // member uid|name
  Map<String,(String,String)> memberUidList={};
  String selectedItem  = Constants.selectedMember;
  Set<String> disabledItems ={};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // WidgetsBinding it is a class of randering,frame,layout ETC
    // instance create a instance of the class
    // addPostFrameCallback, the function will be called after fully building the screen.
    // (_) here will be given a duration but we dont't need the duration that's why we are ignoring using  underscore.
    WidgetsBinding.instance.addPostFrameCallback((_)async{
      final messProvider = context.read<MessProvider>();
      final authProvider = context.read<AuthenticationProvider>();
      if(authProvider.getUserModel!.currentMessId==""){
        debugPrint("you are not mess owner, update page");
        return;
      }
      await messProvider.getMessData(
        isDisposed: ()=>_disposed,
        messId: authProvider.getUserModel!.currentMessId,
        onFail: (message){
          if(!context.mounted) return;
          
          showSnackber(context: context, content: message);
          
        }, 
        onSuccess: (){
          if(!context.mounted) return;

          messOwnerIdController.text = messProvider.getMessModel!.menagerId;
          messOwnerNameController.text = messProvider.getMessModel!.menagerName;
          messNameController.text = messProvider.getMessModel!.messName;
          messAddressController.text = messProvider.getMessModel!.messAddress;
          authorityPhoneController.text = messProvider.getMessModel!.menagerPhone;
          authorityEmailController.text = messProvider.getMessModel!.menagerEmail;
        
        }
      );
    });
  }
  
  @override
  void dispose() {
    _disposed = true;
    messNameController.dispose();
    messAddressController.dispose();
    messOwnerNameController.dispose();
    messOwnerIdController.dispose();
    authorityPhoneController.dispose();
    authorityEmailController.dispose();
    // TODO: implement dispose
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor:Colors.amber.shade100,
        body: SingleChildScrollView(
          child: Column(
            spacing: 10,
            children: [
              SizedBox(
                height:Platform.isIOS? 40:10,
              ),
              Row(
                children: [
                  const Text("Transfer Ownership-"),
                  Switch(
                    value: transferOwnership, 
                    onChanged: (val){
                      setState(() {
                        transferOwnership = val;
                      });
                    }
                  ),
                ],
              ),
              
          
              transferOwnership? getTransferOwnershipData()
              :
              getInfoForUpdateMess(),
              
          
              getMaterialButton(
                context:context,
                label: "Update", 
                ontap:()async{
                  if(amIAdmin(messProvider: messProvider, authProvider: context.read<AuthenticationProvider>())){
                    if(transferOwnership){
                      bool? res =await showConfirmDialog(context: context, title: "you are going to transfer \nyour administrator power. \nAre you sure about this Update.");
                      if(res ?? false){
                        // transfer ownership
                        if(selectedItem != Constants.selectedMember){
                          debugPrint("ownership transfer requesting");
                          await messProvider.transferMessOwnership(
                            adminId: memberUidList[selectedItem ]!.$1, 
                            adimnName: memberUidList[selectedItem ]!.$2, 
                            onFail: (message){
                              if(context.mounted) showSnackber(context: context, content: "Updatation Failed \n$message");
                            },
                            onSuccess: (){
                               showSnackber(context: context, content: "Updatation Successfully.");
                            },
                          );
                          debugPrint("ownership transfer requesting opration done");
                        }
                        else{
                          showSnackber(context: context, content: "At First Select Member");
                        }
                      }
                    }
                    else{
                      if(formKey.currentState!.validate()){
                        bool? res =await showConfirmDialog(context: context, title: "Are you sure about this Update.");
                        if(res?? false){
                          // update mess data
                          await messProvider.updateMessData(
                            onFail: (message){
                              showSnackber(context: context, content: message);
                            }, 
                            messModel: MessModel(
                              messId: "", 
                              messName: messNameController.text.toString().trim(), 
                              messAddress: messAddressController.text.toString().trim(), 
                              menagerId: "", 
                              menagerName: "", 
                              actMenagerId: "", 
                              actMenagerName: "", 
                              mealSessionId: "",
                              menagerPhone: authorityPhoneController.text.toString().trim(), 
                              menagerEmail: authorityEmailController.text.toString().trim(), 
                              messMemberList: [],
                            ),
                            onSuccess: (){
                              if(context.mounted){
                                showSnackber(context: context, content: "Updatation Success.");
                              }
                            }
                          );
                        }
                      }
                      else{
                        if(context.mounted) showSnackber(context: context, content: "fill all required field");
                      }
                    }
                  }
                  else{
                    showSnackber(context: context, content: "you are not mess meneger");
                  }
                }
              ),
          
              SizedBox(
                height: 300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _getAllMemberData()async{
    list.clear();
    disabledItems.clear();
    final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    final messProvider = context.read<MessProvider>();
    
    if(messProvider.getMessModel==null) return list;
    for(Map<String,dynamic> member in messProvider.getMessModel!.messMemberList){
      try {
        DocumentSnapshot documentSnapshot = await firebaseFirestore
          .collection(Constants.users)
          .doc(member[Constants.uId])
          .get();
        if(documentSnapshot.exists){
          list.add("Name: ${documentSnapshot[Constants.fname]} \nId: ${documentSnapshot[Constants.uId]}");
          if(member[Constants.status]==Constants.disable) disabledItems.add(member[Constants.uId]);
          memberUidList["Name: ${documentSnapshot[Constants.fname]} \nId: ${documentSnapshot[Constants.uId]}"] = (member[Constants.uId],documentSnapshot[Constants.fname]);//(uid,name)
          
        }

      
      } catch (e) {
        showSnackber(context: context, content: e.toString());
      }
    }
    return list;
  }

  Widget getTransferOwnershipData(){
    return Container(
              margin: EdgeInsets.all(10),
              // child: FutureBuilder(
              //   future: future, 
              //   builder: builder,
              // ),
              child: DropdownSearch<String>(
                
                key: dropdownKey, // Needed for reset
                items: (String filter,_) => _getAllMemberData(),
                selectedItem : selectedItem ,
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: Constants.selectedMember,
                    border: OutlineInputBorder(),
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                      
                  // Disable specific item visually and functionally
                  disabledItemFn: (item) => disabledItems.contains(item),
                      showSelectedItems: true,
                      itemBuilder: (context, item, isDisabled, isSelected) {//to check isSelected required "showSelectedItems == true"

                    return IgnorePointer(
                      ignoring: isDisabled,
                      child: ListTile(
                        title: Text(
                          item,
                          style : getTextStyleForTitleM().copyWith(
                            color: isDisabled ? Colors.grey : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold: FontWeight.normal
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // always use this function it's tested
                // otherwise we get error because there are few bug here
                onChanged: (value) {
                {
                    if(value!=null){
                      // here we receive only enabled value.
                      setState(() {
                        selectedItem  = value.toString();
                      });
                      debugPrint("Selected enable: $value");
                    }
                  }
                },
              ),
            );
  }

  Widget getInfoForUpdateMess(){
    return Form(
      key: formKey,
      child: Column(
        spacing: 10,
        children: [
          
          FadeInUp(
                    duration: Duration(milliseconds: 100),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey)),
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: TextFormField(
                        controller: messNameController,
                      // onTapOutside: (event) {// close keyboard
                        // FocusScope.of(context).unfocus();
                      // },
                      onChanged: (value){
                        // email = value.trim();
                      },
                      validator: (value) {
                        return nameValidator(value.toString());
                      },
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        label: Text("Mess Name"),
                        border: InputBorder.none,
                                      
                      ),
                    ),
                    ),
                  ),
              
                  FadeInUp(
                    duration: Duration(milliseconds: 300),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey)),
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: TextFormField(
                        controller: messAddressController,
                      onChanged: (value){
      
                      },
                      // onTapOutside: (event) {// close keyboard
                        // FocusScope.of(context).unfocus();
                      // },
                      validator: (value) {
                        return addressValidator(value.toString());
                      },
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        label: Text("Mess Address"),
                        border: InputBorder.none,
                                      
                      ),
                    ),
                    ),
                  ),
              
                  FadeInUp(
                    duration: Duration(milliseconds: 600),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey)),
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: TextFormField(
                        controller: messOwnerNameController,
                        // onTapOutside: (event) {// close keyboard
                        // FocusScope.of(context).unfocus();
                        // },
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          enabled: false,
                          label: Text("Mess Owner Name"),
                          border: InputBorder.none,  
                        ),
                      ),
                    ),
                  ),
              
                  FadeInUp(
                    duration: Duration(milliseconds: 900),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey)),
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: TextFormField(
                        controller: messOwnerIdController,
                        //   onTapOutside: (event) {// close keyboard
                        //   FocusScope.of(context).unfocus();
                        // },
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          enabled: false,
                          label: Text("Mess Owner Id"),
                          border: InputBorder.none,
                                      
                        ),
                      ),
                    ),
                  ),
              
                  FadeInUp(
                    duration: Duration(milliseconds: 1200),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey)),
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: TextFormField(
                        controller: authorityPhoneController,
                        // onTapOutside: (event) {// close keyboard
                        // FocusScope.of(context).unfocus();
                      // },
                      onChanged: (value){
                        // email = value.trim();
                      },
                      validator: (value) {
                        return numberVAladator(value.toString());
                      },
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        label: Text("Autrority Phone"),
                        border: InputBorder.none,
                                      
                      ),
                    ),
                    ),
                  ),
              
                  FadeInUp(
                    duration: Duration(milliseconds: 1500),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey)),
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: TextFormField(
                        controller: authorityEmailController,
                        // onTapOutside: (event) {// close keyboard
                        // FocusScope.of(context).unfocus();
                        // },
                      onChanged: (value){
                        // email = value.trim();
                      },
                      validator: (value) {
                        return emailValidator(value.toString().trim());
                      },
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        label: Text("Autrority Email"),
                        border: InputBorder.none,
                                      
                      ),
                    ),
                    ),
                  ),
        ],
      ),
    );
  }
}




// Image
// whatsapp
// github - white
// linked - white 
// summary -right 
// education - right 
// communication
// project left 