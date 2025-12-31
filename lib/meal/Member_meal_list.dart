import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mess_management/constants.dart';
import 'package:mess_management/helper/helper_method.dart';
import 'package:mess_management/helper/ui_helper.dart';
import 'package:mess_management/providers/authantication_provider.dart';
import 'package:mess_management/providers/meal_provider.dart';
import 'package:mess_management/providers/mess_provider.dart';

import 'package:provider/provider.dart';

class MemberMealList extends StatefulWidget {
  const MemberMealList({super.key});

  @override
  State<MemberMealList> createState() => _MemberMealListState();
}



class _MemberMealListState extends State<MemberMealList> {
  List<Map<String,dynamic>>? memberMealData;

  final dropdownKey = GlobalKey<DropdownSearchState>();
  Map<String,dynamic>? selectedItem;





  // Future<List<String>> _getAllMemberData()async{
  //   list.clear();
  //   disabledItems.clear();
  //   final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  //   final messProvider = context.read<MessProvider>();
  //   final authProvider = context.read<AuthenticationProvider>();
  //   await messProvider.getMessData(
  //     onFail: (message){

  //     }, 
  //     messId:authProvider.getUserModel!.currentMessId,
  //   );

  //   if(messProvider.getMessModel==null) return list;
  //   for(dynamic member in messProvider.getMessModel!.messMemberList){
  //     try {
        
  //         list.add("${member[Constants.fname]}\n${member[Constants.uId]}");
  //         disabledItems.add("${member[Constants.fname]}\n${member[Constants.uId]}");
  //         if(member[Constants.status]==Constants.disable){
  //           disabledItems.add("${member[Constants.fname]}\n${member[Constants.uId]}");
  //         }
        
  //     } catch (e) {
  //       showSnackber(context: context, content: e.toString());
  //     }
  //   }
  //   return list;
  // }

  @override
  void dispose() {

    // TODO: implement dispose
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Expanded(
      // color: Colors.red,
      // width: double.infinity,
      // height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          getMealList(),
        ],
      ),
    );
  }

  Widget getMealList(){
    final mealProvider = context.read<MealProvider>();
    final authProvider = context.read<AuthenticationProvider>();
    final messProvider = context.read<MessProvider>();

    return Expanded(
      child: Column(
        children: [
      
      
          Row(
            children: [
      
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(10),
                  child: DropdownSearch<Map<String, dynamic>>(
                    key: dropdownKey, // Needed for reset
                    // items: ,
                    items: (String filter, _)async => messProvider.getMessMemberList(onFail: (_){}, messId: authProvider.getUserModel!.currentMessId),
                    itemAsString: (item) =>item[Constants.fname]+"\n"+item[Constants.uId], // we can see it as selected value{name, id}. but we receive the currect data {Map}.
                    // asyncItems: (String filter) => _getAllMemberData(),
                    // selectedItem : messProvider.getMessModel!.messMemberList[0] ,
                    

                    // if we dose not use "compareFn" we get an error because we are using here custom data type mean map.
                    compareFn: (item1, item2) => item1[Constants.uId] == item2[Constants.uId],

                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: Constants.selectedMember,
                        border: OutlineInputBorder(),
                        
                      ),
                    ),
                    autoValidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      // if(value==null) return "Fill!";
                      // if(value[Constants.status]==Constants.disable){
                      //   return "The Member Are Disabled!";
                      // }
                      return null;
                    },
                    
                    // dropdownBuilder 
                    dropdownBuilder: (context, selectedItem) {
                      if (selectedItem == null) return Text("");
                      return Column(
                        children: [
                          ListTile(
                          contentPadding: EdgeInsets.all(0),
                          minVerticalPadding: 0,
                          minTileHeight: 0,
                          minLeadingWidth: 0,
                          title: Text(selectedItem[Constants.fname]),
                          subtitle: Text(selectedItem[Constants.uId]),
                          leading: Icon(Icons.person),
                        )
                        ],
                        // leading: Icon(Icons.person),
                      );
                    },
                    popupProps: PopupProps.menu(  
                      showSearchBox: true,
                      disabledItemFn: (item) {
                        return false;
                        // because for check member meal details if we desable it we can't check there details.
                        return item[Constants.status]==Constants.disable;
                      },
                      showSelectedItems: true,
                      itemBuilder: (context, item, isDisabled, isSelected) {//to check isSelected required "showSelectedItems == true"

                        return ListTile(
                          title: Text(
                            item[Constants.fname],
                            style : getTextStyleForTitleM().copyWith(
                              color: isDisabled ? Colors.grey : Colors.black,
                              fontWeight: isSelected? FontWeight.bold : FontWeight.normal
                            )
                          ),
                          subtitle: Text(
                            item[Constants.uId],
                            style : getTextStyleForTitleM().copyWith(
                              color: isDisabled ? Colors.grey : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold: FontWeight.normal
                            )
                          ),
                        );
                        
                      },
                    ),
                    onChanged: (value) {
                      print(value.toString());
                      selectedItem = value;
                    },
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: ()async{
                  if(!(amIAdmin(messProvider: messProvider, authProvider: authProvider) || amIactmenager(messProvider: messProvider, authProvider: authProvider))){
                    showSnackber(context: context, content: "Required Administrator Power");
                    return;
                  }
                  if(selectedItem==null){
                    showSnackber(context: context, content: "Member is not Selected");
                    return;
                  }
                  print(selectedItem.toString()+"\n"+selectedItem?[Constants.uId]);
                  memberMealData = null;
                  memberMealData = await mealProvider.getAllMealListOfAMember(
                    messId: authProvider.getUserModel!.currentMessId, 
                    mealSessionId: authProvider.getUserModel!.mealSessionId, 
                    uId: selectedItem?[Constants.uId], 
                    onFail: (message){showSnackber(context: context, content: "somthing Wrong \n $message");},
                  );
                  if(memberMealData == null) showSnackber(context: context, content: "The Member Meal List Are Empty!");
                  // print(memberMealData.toString());
                  setState(() {
                    
                  });
                }, 
                child: Text("Check"),
              ),
            ],
          ),
          memberMealData!=null? 
          Expanded(
            child: Column(
              children: [
                Card(
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Name: ${memberMealData![0][Constants.fname]}"),
                          Text("UId: ${selectedItem?[Constants.uId]}"),
                          Text("Total Meal: ${getFormatedPrice(value: mealProvider.getTotalMeal)}", style: TextStyle(fontWeight: FontWeight.bold),),
                        ],
                      ),
                    ),
                  )
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: memberMealData!.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date: ${memberMealData![index][Constants.date]}"),
                            Text("Entry Time: ${DateFormat("hh:mm a dd-MM-yyyy").format(memberMealData![index][Constants.createdAt].toDate().toLocal())}"),
                          ],
                        ),
                        trailing: Text("${getFormatedPrice(value: memberMealData![index][Constants.meal])}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                      );
                    },
                  )
                ),
              ],
            ),
          )
          :
          SizedBox.shrink(),
        ],
      ),
    );
  }
}