import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mess_management/helper/helper_method.dart';
import 'package:mess_management/helper/ui_helper.dart';
import 'package:mess_management/home.dart';
import 'package:mess_management/model/user_model.dart';
import 'package:mess_management/providers/authantication_provider.dart';
import 'package:mess_management/services/asset_manager.dart';
import 'package:provider/provider.dart';

class EditInfo extends StatefulWidget {
  const EditInfo({super.key});

  @override
  State<EditInfo> createState() => _EditInfoState();
}

class _EditInfoState extends State<EditInfo> {
  TextEditingController nameContriller = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneContriller = TextEditingController();
  TextEditingController addressContriller = TextEditingController();

  GlobalKey<FormState> FormKey = GlobalKey<FormState>();
  bool checked = false;

  File? finalFileImage;

  @override
  void dispose() {
    nameContriller.dispose();
    addressContriller.dispose();
    emailController.dispose();
    phoneContriller.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  void setData() {
    final authProvider = context.read<AuthenticationProvider>();

    phoneContriller.text = authProvider.getUserModel!.number;
    emailController.text = authProvider.getUserModel!.email;
    nameContriller.text = authProvider.getUserModel!.fname;
    addressContriller.text = authProvider.getUserModel!.fullAddress;
  }

  @override
  void initState() {
    setData();
    // TODO: implement initState
    super.initState();
  }

  void updateInfo() async {
    final authProvider = context.read<AuthenticationProvider>();
    if (FormKey.currentState!.validate() && checked) {
      await authProvider.updateUserDataToFireStore(
        currentUser: UserModel(
          uId: authProvider.getUserModel!.uId,
          email: authProvider.getUserModel!.email,
          image: '',
          number: phoneContriller.text.toString(),
          sessionKey: authProvider.getUserModel!.sessionKey,
          currentMessId: authProvider.getUserModel!.currentMessId,
          mealSessionId: authProvider.getUserModel!.mealSessionId,
          fullAddress: addressContriller.text.toString(),
          fname: nameContriller.text.toString(),
        ),
        fileImage: finalFileImage,
        onSuccess: () {
          showSnackber(context: context, content: "Update Successfully");
          setState(() {});
          Navigator.pop(context);
        },
        onFail: (message) {
          showSnackber(
            context: context,
            content: "Update Failed!\nTry Again.\n$message",
          );
        },
      );
    }
  }

  // select image
  void selectImage({required bool fromCamera}) async {
    File? selectedImage = await pickedImage(
      fromCamera: fromCamera,
      context: context,
      onFail: (message) {
        showSnackber(context: context, content: message);
      },
    );
    if (selectedImage != null) {
      // if the file exist the crop
      File? cropedImage = await cropImage(context, selectedImage.path);
      if (cropedImage != null) {
        // if the file has croped successfully and get existed url now we can do anything with it.
        debugPrint(cropedImage.path);
        finalFileImage = cropedImage;
        setState(() {});
      }
    }
  }

  // this function just show wanted dialog box
  void showImagePickerDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Choos From:", style: getTextStyleForTitleL()),
            scrollable: true,
            content: Column(
              children: [
                ListTile(
                  title: Text("Camera", style: getTextStyleForTitleM()),
                  leading: FaIcon(FontAwesomeIcons.camera),
                  onTap: () {
                    selectImage(fromCamera: true);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text("Gellary", style: getTextStyleForTitleM()),
                  leading: FaIcon(FontAwesomeIcons.images),
                  onTap: () {
                    selectImage(fromCamera: false);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthenticationProvider>();
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text("Edit Info"), backgroundColor: Colors.grey),

        body: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .manual, // keyborow will not despose
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Do You Want To Edit?",
                      style: TextStyle(fontSize: 25),
                    ),
                  ),
                  Checkbox(
                    value: checked,
                    onChanged: (val) {
                      setState(() {
                        checked = !checked;
                      });
                    },
                  ),
                ],
              ),

              finalFileImage != null
                  ? Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        foregroundImage:
                            finalFileImage == null
                                ? AssetImage(AssetsManager.userIcon)
                                : FileImage(File(finalFileImage!.path)),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.black,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            color: Colors.lightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              // pick image from camera or galery
                              showImagePickerDialog();
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                  : Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        foregroundImage:
                            finalFileImage == null
                                ? AssetImage(AssetsManager.userIcon)
                                : FileImage(File(finalFileImage!.path)),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.black,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            color: Colors.lightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              // pick image from camera or galery
                              setState(() {
                                showImagePickerDialog();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
              Column(
                children: [
                  Form(
                    key: FormKey,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade300,
                            border: Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          margin: EdgeInsets.all(10),
                          child: TextFormField(
                            controller: nameContriller,
                            enabled: checked,

                            // onTapOutside: (event) {// close keyboard
                            //   FocusScope.of(context).unfocus();
                            // },
                            validator: (value) {
                              return nameValidator(value.toString());
                            },
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              label: Text("Full Name"),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade300,
                            border: Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          margin: EdgeInsets.all(10),
                          child: TextFormField(
                            controller: emailController,
                            enabled: false,
                            // onTapOutside: (event) {// close keyboard
                            //   FocusScope.of(context).unfocus();
                            // },
                            validator: (value) {
                              return emailValidator(value.toString());
                            },
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              label: Text("Email"),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade300,
                            border: Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          margin: EdgeInsets.all(10),
                          child: TextFormField(
                            controller: phoneContriller,
                            enabled: checked,
                            // onTapOutside: (event) {// close keyboard
                            //   FocusScope.of(context).unfocus();
                            // },
                            validator: (value) {
                              // ^(?:\+88|88)? → allows optional country code +88 or 88.
                              // 01[2-9] → valid operator codes (e.g., 013 to 019).
                              // \d{8}$ → exactly 8 digits after the operator code (total 11 digits).
                              final pattern = RegExp(
                                r'^(?:\+88|88)?01[2-9]\d{8}$',
                              );
                              if (value == null || value.isEmpty) {
                                return 'Phone number is required';
                              }
                              if (!pattern.hasMatch(value.toString())) {
                                return "Enter Valid Phone Number";
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              label: Text("Phone"),
                              border: InputBorder.none,
                              hintText: "Enter Your Phone With Country Code",
                            ),
                          ),
                        ),

                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade300,
                            border: Border(
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          margin: EdgeInsets.all(10),
                          child: TextFormField(
                            controller: addressContriller,
                            enabled: checked,
                            // onTapOutside: (event) {// close keyboard
                            //   FocusScope.of(context).unfocus();
                            // },
                            validator: (value) {
                              return addressValidator(value.toString());
                            },
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              label: Text("Full Address"),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              getButton(
                label: "Update",
                ontap: () {
                  updateInfo();
                },
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
