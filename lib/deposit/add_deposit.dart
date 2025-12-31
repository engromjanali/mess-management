
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mess_management/constants.dart';
import 'package:mess_management/helper/helper_method.dart';
import 'package:mess_management/helper/ui_helper.dart';
import 'package:mess_management/model/deposit_model.dart';
import 'package:mess_management/providers/authantication_provider.dart';
import 'package:mess_management/providers/deposit_provider.dart';
import 'package:mess_management/providers/mess_provider.dart';
import 'package:provider/provider.dart';

class AddDeposit extends StatefulWidget {
  final DepositModel? preDepositModel;
  final Map<String,dynamic> ? preMemberData;
  const AddDeposit({super.key, this.preDepositModel,this.preMemberData });

  @override
  State<AddDeposit> createState() => _AddDepositState();
}

class _AddDepositState extends State<AddDeposit> {
  bool isUpdate = false;
  final formKey = GlobalKey<FormState>();
  final dropdownKey = GlobalKey<DropdownSearchState>();

  FocusNode focusDiscreption = FocusNode();
  FocusNode focusAmount = FocusNode();

  TextEditingController descriptionController = TextEditingController(); 
  TextEditingController amountController = TextEditingController();
  bool isAdd = true;

  List<String > list =[];
  String selectedItem  =Constants.selectedMember;
  Set<String> disabledItems ={};


  Future<List<String>> _getAllMemberData()async{
    list.clear();
    disabledItems.clear();
    final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    final messProvider = context.read<MessProvider>();
    final authProvider = context.read<AuthenticationProvider>();
    await messProvider.getMessData(
      onFail: (message){

      }, 
      messId:authProvider.getUserModel!.currentMessId,
    );

    if(messProvider.getMessModel==null) return list;
    for(dynamic member in messProvider.getMessModel!.messMemberList){
      try {
        
          list.add("${member[Constants.fname]}\n${member[Constants.uId]}");
          if(member[Constants.status]==Constants.disable){
            disabledItems.add("${member[Constants.fname]}\n${member[Constants.uId]}");
          }
        
      } catch (e) {
        showSnackber(context: context, content: e.toString());
      }
    }
    return list;
  }

  void setPreData(){
    isUpdate = true;
    selectedItem  = widget.preMemberData![Constants.fname].toString()+"\n"+widget.preMemberData![Constants.uId].toString();
    descriptionController.text = widget.preDepositModel!.description;
    amountController.text = widget.preDepositModel!.amount.toString();
    isAdd = widget.preDepositModel?.type == Constants.deposit;
  }

  @override
  void initState() {
    if(widget.preDepositModel != null && widget.preMemberData!=null){
      setPreData();
    }
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    // TODO: implement dispose
    super.dispose();
  }
  


  @override
  Widget build(BuildContext context) {
    final depositProvider = context.watch<DepositProvider>();
    final messProvider = context.read<MessProvider>();
    final authProvider = context.read<AuthenticationProvider>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.green.shade50,
        resizeToAvoidBottomInset: true,
        appBar: isUpdate? AppBar(
          title: Text("Edit Deposit", style: getTextStyleForTitleXL(),),
          backgroundColor: Colors.grey,
        ):null,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height:Platform.isIOS? 40:10,
              ),

              SwitchListTile(          
                title: Text("Tnx Type"),
                subtitle: isAdd? Text("Deposit") : Text("Refund"),
                value: isAdd,
                onChanged: (val){
                  if(!isUpdate){
                    setState(() {
                      isAdd = val;
                    });
                  }
                  else{
                    showSnackber(context: context, content: "For Update \"Entry Type\" Can't Be Changed");
                  }
                },
                secondary: Icon(Icons.playlist_add_check_circle), //Icon(Icons.dark_mode),
                activeColor: Colors.black,
                activeTrackColor: Colors.blue,
              ),
                
              Container(
                margin: EdgeInsets.all(10),
                // child: FutureBuilder(
                //   future: future, 
                //   builder: builder,
                // ),
                child: DropdownSearch<String>(
                  enabled: (!isUpdate),
                  key: dropdownKey, // Needed for reset
                  items: (String filter,_) => _getAllMemberData(),
                  selectedItem : selectedItem,
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
                      return ListTile(
                        title: Text(
                          item,
                          style: TextStyle(
                            color: isDisabled ? Colors.grey : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold: FontWeight.normal
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
              ),
                  
              Form(
                key: formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: descriptionController,
                        // onTapOutside: (event) => FocusScope.of(context).unfocus(),
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        // autofocus: true,
                        focusNode: focusDiscreption,
                        onFieldSubmitted: (value){
                          FocusScope.of(context).requestFocus(focusAmount);
                        },
                        // validator: (value) {
                        //   if(value.toString().trim()==""){
                        //     return "";
                        //   }
                        //   return null;
                        // },
              
                        decoration: FromFieldDecoration(
                          hintText: "Write About The Deposit",
                          label: "Discreption (Optional)",
                        )
                      ),
                    ),
                
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: amountController,
                        // onTapOutside: (event) {
                        //   FocusScope.of(context).unfocus();
                        // },
                        // autofocus: true,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.number,
                        focusNode: focusAmount,
                        onFieldSubmitted: (value){
                          FocusScope.of(context).unfocus();
                        },
                        validator: (value) {
                          return validatePrice(value.toString());
                        },
                        decoration: FromFieldDecoration(
                          hintText: "How Much?",
                          label: "Amount",
                        )
                      ),
                    ),
                  ],
                )
              ),   
              
              SizedBox(
                height: 50,
              ),
              
              depositProvider.isLoading? showCircularProgressIndicator()
              : 
              getButton(
                label: isUpdate?"Update":"Submit", 
                ontap: ()async{
                  if(!(amIAdmin(messProvider: messProvider, authProvider: authProvider) || amIactmenager(messProvider: messProvider, authProvider: authProvider))){
                    showSnackber(context: context, content: "Required Administrator Power");
                    return;
                  }
              
                  bool valided  = (formKey.currentState!.validate() && selectedItem != Constants.selectedMember );
                  
                  if(valided){
                    if(isUpdate){
                      await depositProvider.updateADepositTransaction(
                        depositModel: DepositModel(
                          tnxId: widget.preDepositModel!.tnxId, 
                          amount: double.parse(amountController.text.toString()), 
                          description: descriptionController.text.toString(), 
                          type: widget.preDepositModel!.type, 
                        ), 
                        extraAmount: double.parse(amountController.text.toString()) - widget.preDepositModel!.amount ,
                        uId: widget.preMemberData![Constants.uId].toString(), 
                        messId: authProvider.getUserModel!.currentMessId, 
                        mealSessionId: authProvider.getUserModel!.mealSessionId,
                        onFail: (message ) { 
                          showSnackber(context: context, content: "Updaate Failed! \n$message");
                        },
                        onSuccess: (){ 
                          formKey.currentState!.reset();
                          showSnackber(context: context, content: "Update Success!");
                          Navigator.pop(context);
                        }
                      );
                      // we should clear pre data other wise pre grabage data can make wrong submesion
                      isUpdate = false;
                      amountController.clear();
                      descriptionController.clear();
                      selectedItem  = Constants.selectedMember; // importent because dropdown key was rest but variable still hold pre value
                      dropdownKey.currentState!.clear();
              
                      setState(() {
                            
                      });
                    }
                    else{
                      await depositProvider.addADepositTransaction(
                        depositModel: DepositModel(
                          tnxId: DateTime.now().millisecondsSinceEpoch.toString(), 
                          amount: double.parse(amountController.text.toString()), 
                          description: descriptionController.text.toString(), 
                          type: isAdd? Constants.deposit : Constants.refund, 
                        ), 
                        uId: selectedItem .split("\n")[1], 
                        messId: authProvider.getUserModel!.currentMessId, 
                        mealSessionId: authProvider.getUserModel!.mealSessionId,
                        onFail: (message ) { 
                          showSnackber(context: context, content: "Deposit Failed! \n$message");
                        },
                        onSuccess: (){ 
                          formKey.currentState!.reset();
                          showSnackber(context: context, content: "Deposit Successed!");
                        }
                      );
                      isUpdate = false;
                      amountController.clear();
                      descriptionController.clear();
                      selectedItem  =  Constants.selectedMember;
                      dropdownKey.currentState!.clear();
              
                      setState(() {
                            
                      });
                    }
                  }
                  else{
                    showSnackber(context: context, content: "Fill All Required Field");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}