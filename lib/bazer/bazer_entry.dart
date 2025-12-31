
import 'package:auto_size_text/auto_size_text.dart';
import 'package:mess_management/model/bazer_model.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mess_management/constants.dart';
import 'package:mess_management/helper/helper_method.dart';
import 'package:mess_management/helper/ui_helper.dart';
import 'package:mess_management/providers/authantication_provider.dart';
import 'package:mess_management/providers/bazer_provider.dart';
import 'package:mess_management/providers/mess_provider.dart';
import 'package:provider/provider.dart';

class BazerEntryScreen extends StatefulWidget {
  final BazerModel? preBazerModel;
  const BazerEntryScreen({super.key,required this.preBazerModel});

  @override
  State<BazerEntryScreen> createState() => _BazerEntryScreenState();
}

class _BazerEntryScreenState extends State<BazerEntryScreen> {
  double totalAmount=0;
  bool isUpdate = false;
  TimeOfDay? time;
  DateTime? date;

  List<Map<String, dynamic>> bazerList = [];

  final dropdownKey = GlobalKey<DropdownSearchState>();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();

  Map<String,dynamic>? selectedItem;



  void setPreData(){
    isUpdate = (widget.preBazerModel!=null);
    if((widget.preBazerModel==null)) return;
    bazerList = (widget.preBazerModel!.bazerList as List<dynamic>).map((x)=> Map<String, dynamic> .from(x as Map)).toList();
    
    DateTime dateTime = DateFormat("h:mm a").parse(widget.preBazerModel!.bazerTime);
    time = TimeOfDay.fromDateTime(dateTime);
    timeController.text = widget.preBazerModel!.bazerTime;

    date = DateFormat("dd/MM/yyyy").parse(widget.preBazerModel!.bazerDate);
    dateController.text = widget.preBazerModel!.bazerDate;

    selectedItem  ={
      Constants.fname : widget.preBazerModel!.byWho[Constants.fname],
      Constants.uId : widget.preBazerModel!.byWho[Constants.uId],
      Constants.status : Constants.enable,
    };

    setState(() {
      setTotalPrice();
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    setPreData();
    super.initState();
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();

    super.dispose();

  }


  @override
  Widget build(BuildContext context) {

    final messProvider = context.read<MessProvider>();
    final authProvider = context.read<AuthenticationProvider>();
    final bazerProvider = context.watch<BazerProvider>();



    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text("Bazer Entry", style: getTextStyleForTitleXL(),),
        backgroundColor: Colors.grey,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
                Container(
                  margin: EdgeInsets.all(10),
                  child: DropdownSearch<Map<String, dynamic>>(
                    key: dropdownKey, // Needed for reset
                    items: (String filter,_)async => messProvider.getMessMemberList(onFail: (_){}, messId: authProvider.getUserModel!.currentMessId),
                    itemAsString: (item) =>item[Constants.fname]+"\n"+item[Constants.uId], // we can see it as selected value{name, id}. but we receive the currect data {Map}.
                    // asyncItems: (String filter) => _getAllMemberData(),
                    selectedItem : selectedItem,
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
                      if(value==null) return "Fill!";
                      if(value[Constants.status]==Constants.disable){
                        return "The Member Are Disabled!";
                      }
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
                        return item[Constants.status]==Constants.disable;
                      },
                      
                      showSelectedItems: true,
                      itemBuilder: (context, item, isDisabled, isSelected) {//to check isSelected required "showSelectedItems == true"

                        return ListTile(
                          title: Text(
                            item[Constants.fname],
                            style : getTextStyleForTitleM().copyWith(
                              color: isDisabled ? Colors.grey : Colors.black,
                              fontWeight: isSelected? FontWeight.bold: FontWeight.normal
                            )
                          ),
                          subtitle: Text(
                            item[Constants.uId],
                            style : getTextStyleForTitleM().copyWith(
                              color: isDisabled ? Colors.grey : Colors.black,
                            )
                          ),
                        );
                        
                      },
                    ),
                    onChanged: (value) {
                      print(value.toString());
                      selectedItem = value;
                
                      // if(messProvider.getMessModel!.messMemberList[0] == value){
                      //   dropdownKey.currentState?.clear();
                      // }
                    },
                  ),
                ),
            
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onTap: () async{
        
                        date = await showDatePicker(
                          // fieldHintText: "mm/dd/YYYY",
                          fieldLabelText: "Enter Date (MM/DD/YYYY)", // defalut "Enter Date"
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate : DateTime(2000,12,30,12,59,59),
                          lastDate: DateTime(2050),
                          initialDatePickerMode: DatePickerMode.day,
                          initialEntryMode:DatePickerEntryMode.calendar,
                          // helpText: "Set Date", // default "Select date"
                        );
                        if(date!=null){
                          dateController.text = DateFormat("dd/MM/yyyy").format(date!);
                        }
                      },
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          
                        ),
                        label: FittedBox(child: Text("Date(dd/MM/yyyy)")),
                        hintText: "Select date",
        
                      ),
                    ),
                  ),
        
                  SizedBox(width: 10,),
        
                  Expanded(
                    child: TextField(
                      onTap: () async{
                        time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          initialEntryMode: TimePickerEntryMode.dial,
                          helpText: "Set Time",
                        );
                        if(time!=null){
                          timeController.text = formatTimeOfDay(time!);
                        }
                      },
                      readOnly: true,
                      controller: timeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                    
                        ),
                        label: FittedBox(child: Text("Time(HH:MM A/P)")),
                        hintText: "Select Time",
                      ),
                    ),
                  ),
                ],
              ),
            ),
        
            Card(
              // color: Colors.,
              child: ListTile(
                minTileHeight: 40,
                title: Text("Total Cost \$ $totalAmount TK", style: TextStyle(fontSize: 20),),
              ),
            ),

            SizedBox(
              height: 400,
              child: Stack(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 20, top: 10),
                    height: 1000,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Color(0xFFF2F2F2),
                      border: Border(
                        
                      )
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("SL NO", style: TextStyle(fontSize: 18),),
                              Text("Product", style: TextStyle(fontSize: 18),),
                              Text("Price", style: TextStyle(fontSize: 18),),
                              Text("E/D", style: TextStyle(fontSize: 18),),
                            ],
                          ),
                        ),
                    
                        Divider(),
                    
        
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: bazerList.length,
                            itemBuilder: (context, index){
                              Map<String,dynamic> value = bazerList[index];
                              print(value);
                              return 
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                  
                                      SizedBox(
                                        width: 40,
                                        child: Center(
                                          child: AutoSizeText(
                                            "${index+1}",  
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                            style: getTextStyleForSubTitleM().copyWith(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            minFontSize: 10,
                                          ),
                                        ),
                                      ),
                                  
                                  
                                      // Divider
                                      getVerticalDevider(color: Colors.grey.shade300,height:40 ,width: 1),
                                  
                                      // Amount input field
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(4),
                                          child: AutoSizeText(
                                            value[Constants.product],  
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                            style: getTextStyleForSubTitleL().copyWith(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            minFontSize: 12,
                                          ),
                                        ),
                                      ),
                                  
                                      getVerticalDevider(),
                                  
                                      // Amount
                                      SizedBox(
                                        width: 80,
                                        child: Center(
                                          child: AutoSizeText(
                                            value[Constants.price],  
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                            style: getTextStyleForSubTitleM().copyWith(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            minFontSize: 8,
                                          ),
                                        ),
                                      ),
                                  
                                      getVerticalDevider(),
                                  
                                      getCustomIcon(
                                        iconData: Icons.edit, 
                                        ontap:()async{
                                          await showInputDialog(product: value[Constants.product], price:value[Constants.price], index: index);
                                          setState(() {
                                          });
                                        }
                                      ),
                                      getCustomIcon(
                                        iconData: Icons.close, 
                                        ontap: () {  
                                          setState(() {
                                            bazerList.removeAt(index);
                                            setTotalPrice();
                                          });
                                        }
                                      ),
                                    ]
                                  )   
                                );
                            }
                          ),
                        ),
                        // list of product is here.
                        // Expanded(
                        //   child: SingleChildScrollView(
                        //     scrollDirection: Axis.vertical,
                        //     child: Column(
                        //       // "row.asMap" make it a map where key is index and value is the map
                        //       // "entries" store list of pair<key, value>
                        //       // "entries.map((entry){})" entry is a pair
                        //       children: bazerList.asMap().entries.map((entry){
                        //         int index = entry.key;
                        //         Map value = entry.value;
                        //         return ListTile(
                        //           contentPadding: EdgeInsets.only(left: 5),
                        //           leading: CircleAvatar(
                        //             backgroundColor: Colors.grey.shade500,
                        //             child: Text("${index}", style: TextStyle(fontSize: 20)),
                        //           ),
                        //           title: Text(value[Constants.product], style : getTextStyleForTitleM(), textAlign: TextAlign.center,),
                        //           trailing: Row(
                        //             mainAxisSize: MainAxisSize.min,
                        //             children: [
                        //               Text(value[Constants.price], style: TextStyle(fontSize: 16),),
                        //               IconButton(
                        //                 onPressed: ()async{
                        //                   await showInputDialog(product: value[Constants.product], price:value[Constants.price], index: index);
                        //                   setState(() {
                        //                   });
                        //                 }, 
                        //                 icon: Icon(Icons.edit_square,color: Colors.green,)
                        //               ),
                        //               IconButton(
                        //                 onPressed: (){
                        //                   setState(() {
                        //                     bazerList.removeAt(index);
                        //                   });
                        //                 }, 
                        //                 icon: Icon(Icons.disabled_by_default_rounded,color: Colors.red.shade800,)
                        //               ),
                        //             ],
                        //           ),
                        //         );
                        //         // return Row(
                        //         //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                        //         //   children: [
                        //         //       Text("$index", style: TextStyle(fontSize: 16),),
                        //         //       Text("${value["${BazerEntry.description}"]}",style: TextStyle(fontSize: 16),),
                        //         //       Text("${value["${BazerEntry.price}"]}",style: TextStyle(fontSize: 16),),
                        //         //     ],
                        //         // );
                        //       }).toList(),   
                        //     ),
                        //   ),
                        // )
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    left: 1/2,
                    right: 1/2,
              
                    child: GestureDetector(
                      onTap: () async{
                        await showInputDialog();
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade700,
                        child: Icon(Icons.add,color: Colors.blue,),
                      ),
                    )
                  ),                  
                ],
              ),
            ),
        
            SizedBox(
              height: 50,
            ),
            bazerProvider.isLoading? showCircularProgressIndicator()
            : 
            getButton(
              label:  isUpdate?"update" : "save", 
              ontap: ()async{
                if(amIAdmin(messProvider:messProvider , authProvider: authProvider) || amIactmenager(messProvider:messProvider , authProvider: authProvider)){
                  if(selectedItem == null){
                    showSnackber(context: context, content: "Member Was Not Slelcted.");
                    return;
                  }
                  if(date==null){
                    showSnackber(context: context, content: "Date Was Not Slelcted.");
                    return;
                  }
                  if(time==null){
                    showSnackber(context: context, content: "Time Was Not Slelcted.");
                    return;
                  }
                  if(bazerList.isEmpty){
                    showSnackber(context: context, content: "The list of bazer are empty");
                    return;
                  }
                  else{
                    // all valid
                    try {
                      setTotalPrice();
                    } catch (e) {
                      print(e);
                      return;
                    }
                    BazerModel  bazerModel = isUpdate?
                    BazerModel(
                      tnxId: widget.preBazerModel!.tnxId, 
                      amount: totalAmount, 
                      bazerList: bazerList,
                      bazerTime: formatTimeOfDay(time!).toString(),
                      bazerDate: DateFormat("dd/MM/yyyy").format(date!).toString(),
                      byWho: selectedItem!,
                    )
                    :
                    BazerModel(
                      tnxId: DateTime.now().millisecondsSinceEpoch.toString(), 
                      amount: totalAmount, 
                      bazerList: bazerList,
                      bazerTime: formatTimeOfDay(time!).toString(),
                      bazerDate: DateFormat("dd/MM/yyyy").format(date!).toString(),
                      byWho: selectedItem!,
                    );
                    print(totalAmount.toString()+"a");
        
                    isUpdate?
                    await bazerProvider.updateABazerTransaction(
                      bazerModel: bazerModel, 
                      messId: authProvider.getUserModel!.currentMessId, 
                      mealSessionId: authProvider.getUserModel!.mealSessionId, 
                      onFail: (message ) { 
                        showSnackber(context: context, content: "Failed!\n$message");
                      },
                      onSuccess: (){
                        isUpdate = false;
                        dropdownKey.currentState?.clear();
                        date =null;
                        time =null;
                        dateController.clear();
                        timeController.clear();
                        
                        showSnackber(context: context, content: "Updated!");
                      }, 
                      extraAdd: (bazerModel.amount - widget.preBazerModel!.amount) ,
                    )
        
                    :
                    await bazerProvider.addABazerTransaction(
                      bazerModel: bazerModel, 
                      messId: authProvider.getUserModel!.currentMessId, 
                      mealSessionId: authProvider.getUserModel!.mealSessionId, 
                      onFail: (message ) { 
                        showSnackber(context: context, content: "Bazer Entry Failed!\n$message");
                      },
                      onSuccess: (){
                        showSnackber(context: context, content: "Bazer Entry Successed!");
                      }
                    );
        
                    // success 
                    setState(() {
                      bazerList.clear();
                      setTotalPrice();
                    });
                  }
                }
                else{
                  showSnackber(context: context, content: "Required Menager/Act Menager power");
                }
              }
            ),
            SizedBox(
              height: 30,
            )
          ],
        ),
      ),
    );
  }

  Future<void> showInputDialog({String product="", String price="", int? index})async{
    bool isUpdate = index!=null ? true:false;


    final formKey = GlobalKey<FormState>();
    FocusNode focusProduct = FocusNode();
    FocusNode focusPrice = FocusNode();
    
    Map<String,dynamic>? map = await showDialog(
      context: context, 
      builder: (context) { 
        TextEditingController productController = TextEditingController();
        TextEditingController priceController = TextEditingController();

        productController.text = product;
        priceController.text = price;
        
        return AlertDialog(
        title: Text("Add Product-",style : getTextStyleForTitleL()),
        scrollable: true,
        content: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: productController ,
                textInputAction: TextInputAction.next,
                autofocus: true,
                focusNode: focusProduct,
                onFieldSubmitted: (value){
                  FocusScope.of(context).requestFocus(focusPrice);
                },
                validator: (value) {
                  if(value.toString().trim()==""){
                    return "Empty Field!";
                  }
                  return null;
                },
                onChanged: (value) {
                  product = value.trim();
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    
                  ),
                  label: Text("Product Name-")
                ),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: priceController,
                autofocus: true,
                focusNode: focusPrice,
                onFieldSubmitted: (value){
                  FocusScope.of(context).unfocus();
                },
                keyboardType: TextInputType.numberWithOptions(decimal: true,signed: true),
                textInputAction: TextInputAction.done,
                validator: (value) => validatePrice(value.toString()),
                onChanged: (value){
                  price = value.trim();
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    
                  ),
                  label: Text("Product Price-")
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.pop(context);
            }, 
            child: Text("Cancle"),
          ),
          TextButton(
            onPressed: (){
              if(formKey.currentState!.validate()){
                Navigator.pop(context, {Constants.product : product, Constants.price: price});
              }
            }, 
            child:isUpdate? Text("Update") : Text("Add"),

          ),
        ],
      );
      }
    );
    print(map);
    if(map!=null){
      
        isUpdate?
        bazerList[index] = {
          Constants.price : price,
          Constants.product : product, 
        }
        : 
        bazerList.add(
          {
            Constants.product : product, 
            Constants.price : price,
          }
        );
        setState(() {
          setTotalPrice();
        });
      
    }
  }

  setTotalPrice(){
    try {
      totalAmount = 0;
      bazerList.map((x){
        totalAmount += double.parse(x[Constants.price]);
      }).toList();
    } catch (e) {
      throw e;
    }
  }
}
