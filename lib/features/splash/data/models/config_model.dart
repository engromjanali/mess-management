import 'package:clean_boilerplate/features/splash/domain/entities/config_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'config_model.freezed.dart';
part 'config_model.g.dart';

ConfigModel configModelFromJson(String str) => ConfigModel.fromJson(json.decode(str));

String configModelToJson(ConfigModel data) => json.encode(data.toJson());

@freezed
abstract class ConfigModel with _$ConfigModel {
  const ConfigModel._();

  const factory ConfigModel({
    required String restaurantName,
    required String restaurantPhone,
    required List<RestaurantScheduleTime> restaurantScheduleTime,
    required String restaurantLogo,
    required String restaurantAddress,
    required String restaurantEmail,
    required RestaurantLocationCoverage restaurantLocationCoverage,
    required int minimumOrderValue,
    required BaseUrls baseUrls,
    required String currencySymbol,
    required int deliveryCharge,
    required DeliveryManagement deliveryManagement,
    required List<Branch> branches,
    required bool emailVerification,
    required bool phoneVerification,
    required String currencySymbolPosition,
    required String country,
    required bool selfPickup,
    required bool delivery,
    required StoreConfig playStoreConfig,
    required StoreConfig appStoreConfig,
    required List<SocialMediaLink> socialMediaLink,
    required String softwareVersion,
    required int decimalPointSettings,
    required int scheduleOrderSlotDuration,
    required String timeFormat,
    required List<PromotionCampaign> promotionCampaign,
    required SocialLogin socialLogin,
    required int walletStatus,
    required int loyaltyPointStatus,
    required int refEarningStatus,
    required int loyaltyPointItemPurchasePoint,
    required int loyaltyPointExchangeRate,
    required int loyaltyPointMinimumPoint,
    required int customerReferredDiscountStatus,
    required String customerReferredDiscountType,
    required int customerReferredDiscountAmount,
    required String customerReferredValidityType,
    required int customerReferredValidityValue,
    required Whatsapp whatsapp,
    required CookiesManagement cookiesManagement,
    required int toggleDmRegistration,
    required int isVegNonVegActive,
    required int otpResendTime,
    required DigitalPaymentInfo digitalPaymentInfo,
    required int digitalPaymentStatus,
    required List<ActivePaymentMethodList> activePaymentMethodList,
    required String cashOnDelivery,
    required String digitalPayment,
    required String offlinePayment,
    required int guestCheckout,
    required int partialPayment,
    required String partialPaymentCombineWith,
    required int addFundToWallet,
    required AppleLogin appleLogin,
    required int cutleryStatus,
    required int firebaseOtpVerificationStatus,
    required CustomerVerification customerVerification,
    required String footerCopyrightText,
    required String footerDescriptionText,
    required CustomerLogin customerLogin,
    required int googleMapStatus,
    required bool maintenanceMode,
    required AdvanceMaintenanceMode advanceMaintenanceMode,
    required int halalTagStatus,
    required int maxImageUploadSize,
    required List<AcceptedImageExtensionArray> acceptedImageExtensionArray,
    required List<String> acceptedImageExtension,
  }) = _ConfigModel;

  factory ConfigModel.fromJson(Map<String, dynamic> json) => _$ConfigModelFromJson(json);

  ConfigEntity toEntity() {
    return ConfigEntity(
      restaurantName: restaurantName,
      restaurantPhone: restaurantPhone,
      restaurantScheduleTime: restaurantScheduleTime.map((e) => e.toEntity()).toList(),
      restaurantLogo: restaurantLogo,
      restaurantAddress: restaurantAddress,
      restaurantEmail: restaurantEmail,
      restaurantLocationCoverage: restaurantLocationCoverage.toEntity(),
      minimumOrderValue: minimumOrderValue,
      baseUrls: baseUrls.toEntity(),
      currencySymbol: currencySymbol,
      deliveryCharge: deliveryCharge.toDouble(),
      deliveryManagement: deliveryManagement.toEntity(),
      branches: branches.map((e) => e.toEntity()).toList(),
      emailVerification: emailVerification,
      phoneVerification: phoneVerification,
      currencySymbolPosition: currencySymbolPosition,
      country: country,
      selfPickup: selfPickup,
      delivery: delivery,
      playStoreConfig: playStoreConfig.toEntity(),
      appStoreConfig: appStoreConfig.toEntity(),
      socialMediaLink: socialMediaLink.map((e) => e.toEntity()).toList(),
      softwareVersion: softwareVersion,
      decimalPointSettings: decimalPointSettings,
      scheduleOrderSlotDuration: scheduleOrderSlotDuration,
      timeFormat: timeFormat,
      promotionCampaign: promotionCampaign.map((e) => e.toEntity()).toList(),
      socialLogin: socialLogin.toEntity(),
      walletStatus: walletStatus,
      loyaltyPointStatus: loyaltyPointStatus,
      refEarningStatus: refEarningStatus,
      loyaltyPointItemPurchasePoint: loyaltyPointItemPurchasePoint,
      loyaltyPointExchangeRate: loyaltyPointExchangeRate,
      loyaltyPointMinimumPoint: loyaltyPointMinimumPoint,
      customerReferredDiscountStatus: customerReferredDiscountStatus,
      customerReferredDiscountType: customerReferredDiscountType,
      customerReferredDiscountAmount: customerReferredDiscountAmount,
      customerReferredValidityType: customerReferredValidityType,
      customerReferredValidityValue: customerReferredValidityValue,
      whatsapp: whatsapp.toEntity(),
      cookiesManagement: cookiesManagement.toEntity(),
      toggleDmRegistration: toggleDmRegistration,
      isVegNonVegActive: isVegNonVegActive,
      otpResendTime: otpResendTime,
      digitalPaymentInfo: digitalPaymentInfo.toEntity(),
      digitalPaymentStatus: digitalPaymentStatus,
      activePaymentMethodList: activePaymentMethodList.map((e) => e.toEntity()).toList(),
      isCashOnDeliveryActive: cashOnDelivery.contains('true'),
      isDigitalPaymentActive: digitalPayment.contains('true'),
      isOfflinePaymentActive: offlinePayment.contains('true'),
      isGuestCheckoutActive: guestCheckout == 1,
      isPartialPaymentActive: partialPayment == 1,
      partialPaymentCombineWith: partialPaymentCombineWith,
      isAddFundToWalletActive: addFundToWallet == 1,
      appleLogin: appleLogin.toEntity(),
      isCutleryActive: cutleryStatus == 1,
      isFirebaseOtpVerificationActive: firebaseOtpVerificationStatus == 1,
      customerVerification: customerVerification.toEntity(),
      footerCopyrightText: footerCopyrightText,
      footerDescriptionText: footerDescriptionText,
      customerLogin: customerLogin.toEntity(),
      googleMapStatus: googleMapStatus,
      maintenanceMode: maintenanceMode,
      advanceMaintenanceMode: advanceMaintenanceMode.toEntity(),
      isHalalTagActive: halalTagStatus == 1,
      maxImageUploadSize: maxImageUploadSize,
      acceptedImageExtensionArray: acceptedImageExtensionArray.map((e) => e.toEntity()).toList(),
      acceptedImageExtension: acceptedImageExtension,
    );
  }
}

@freezed
abstract class AcceptedImageExtensionArray with _$AcceptedImageExtensionArray {
  const AcceptedImageExtensionArray._();
  const factory AcceptedImageExtensionArray({required String key, required String value}) = _AcceptedImageExtensionArray;

  factory AcceptedImageExtensionArray.fromJson(Map<String, dynamic> json) => _$AcceptedImageExtensionArrayFromJson(json);

  AcceptedImageExtensionArrayEntity toEntity() {
    return AcceptedImageExtensionArrayEntity(key: key, value: value);
  }
}

@freezed
abstract class ActivePaymentMethodList with _$ActivePaymentMethodList {
  const ActivePaymentMethodList._();
  const factory ActivePaymentMethodList({required String gateway, required String gatewayTitle, required String gatewayImage}) = _ActivePaymentMethodList;

  factory ActivePaymentMethodList.fromJson(Map<String, dynamic> json) => _$ActivePaymentMethodListFromJson(json);

  ActivePaymentMethodListEntity toEntity() {
    return ActivePaymentMethodListEntity(gateway: gateway, gatewayTitle: gatewayTitle, gatewayImage: gatewayImage);
  }
}

@freezed
abstract class AdvanceMaintenanceMode with _$AdvanceMaintenanceMode {
  const AdvanceMaintenanceMode._();

  const factory AdvanceMaintenanceMode({
    required int maintenanceStatus,
    required SelectedMaintenanceSystem selectedMaintenanceSystem,
    required MaintenanceMessages maintenanceMessages,
    required MaintenanceTypeAndDuration maintenanceTypeAndDuration,
  }) = _AdvanceMaintenanceMode;

  factory AdvanceMaintenanceMode.fromJson(Map<String, dynamic> json) => _$AdvanceMaintenanceModeFromJson(json);

  AdvanceMaintenanceModeEntity toEntity() {
    return AdvanceMaintenanceModeEntity(
      maintenanceStatus: maintenanceStatus,
      selectedMaintenanceSystem: selectedMaintenanceSystem.toEntity(),
      maintenanceMessages: maintenanceMessages.toEntity(),
      maintenanceTypeAndDuration: maintenanceTypeAndDuration.toEntity(),
    );
  }
}

@freezed
abstract class MaintenanceMessages with _$MaintenanceMessages {
  const MaintenanceMessages._();

  const factory MaintenanceMessages({required int businessNumber, required int businessEmail, required String maintenanceMessage, required String messageBody}) = _MaintenanceMessages;

  factory MaintenanceMessages.fromJson(Map<String, dynamic> json) => _$MaintenanceMessagesFromJson(json);

  MaintenanceMessagesEntity toEntity() {
    return MaintenanceMessagesEntity(businessNumber: businessNumber, businessEmail: businessEmail, maintenanceMessage: maintenanceMessage, messageBody: messageBody);
  }
}

@freezed
abstract class MaintenanceTypeAndDuration with _$MaintenanceTypeAndDuration {
  const MaintenanceTypeAndDuration._();

  const factory MaintenanceTypeAndDuration({required String maintenanceDuration, required dynamic startDate, required dynamic endDate}) = _MaintenanceTypeAndDuration;

  factory MaintenanceTypeAndDuration.fromJson(Map<String, dynamic> json) => _$MaintenanceTypeAndDurationFromJson(json);

  MaintenanceTypeAndDurationEntity toEntity() {
    return MaintenanceTypeAndDurationEntity(maintenanceDuration: maintenanceDuration, startDate: startDate, endDate: endDate);
  }
}

@freezed
abstract class SelectedMaintenanceSystem with _$SelectedMaintenanceSystem {
  const SelectedMaintenanceSystem._();

  const factory SelectedMaintenanceSystem({required int branchPanel, required int customerApp, required int webApp, required int deliverymanApp}) = _SelectedMaintenanceSystem;

  factory SelectedMaintenanceSystem.fromJson(Map<String, dynamic> json) => _$SelectedMaintenanceSystemFromJson(json);

  SelectedMaintenanceSystemEntity toEntity() {
    return SelectedMaintenanceSystemEntity(branchPanel: branchPanel, customerApp: customerApp, webApp: webApp, deliverymanApp: deliverymanApp);
  }
}

@freezed
abstract class StoreConfig with _$StoreConfig {
  const StoreConfig._();

  const factory StoreConfig({required bool status, required String link, required String minVersion}) = _StoreConfig;

  factory StoreConfig.fromJson(Map<String, dynamic> json) => _$StoreConfigFromJson(json);

  StoreConfigEntity toEntity() {
    return StoreConfigEntity(status: status, link: link, minVersion: minVersion);
  }
}

@freezed
abstract class AppleLogin with _$AppleLogin {
  const AppleLogin._();
  const factory AppleLogin({required String loginMedium, required int status, required String clientId}) = _AppleLogin;

  factory AppleLogin.fromJson(Map<String, dynamic> json) => _$AppleLoginFromJson(json);

  AppleLoginEntity toEntity() {
    return AppleLoginEntity(loginMedium: loginMedium, status: status, clientId: clientId);
  }
}

@freezed
abstract class BaseUrls with _$BaseUrls {
  const BaseUrls._();

  const factory BaseUrls({
    required String productImageUrl,
    required String customerImageUrl,
    required String bannerImageUrl,
    required String categoryImageUrl,
    required String categoryBannerImageUrl,
    required String reviewImageUrl,
    required String notificationImageUrl,
    required String restaurantImageUrl,
    required String deliveryManImageUrl,
    required String chatImageUrl,
    required String promotionalUrl,
    required String kitchenImageUrl,
    required String branchImageUrl,
    required String gatewayImageUrl,
    required String paymentImageUrl,
    required String cuisineImageUrl,
  }) = _BaseUrls;

  factory BaseUrls.fromJson(Map<String, dynamic> json) => _$BaseUrlsFromJson(json);

  BaseUrlsEntity toEntity() {
    return BaseUrlsEntity(
      productImageUrl: productImageUrl,
      customerImageUrl: customerImageUrl,
      bannerImageUrl: bannerImageUrl,
      categoryImageUrl: categoryImageUrl,
      categoryBannerImageUrl: categoryBannerImageUrl,
      reviewImageUrl: reviewImageUrl,
      notificationImageUrl: notificationImageUrl,
      restaurantImageUrl: restaurantImageUrl,
      deliveryManImageUrl: deliveryManImageUrl,
      chatImageUrl: chatImageUrl,
      promotionalUrl: promotionalUrl,
      kitchenImageUrl: kitchenImageUrl,
      branchImageUrl: branchImageUrl,
      gatewayImageUrl: gatewayImageUrl,
      paymentImageUrl: paymentImageUrl,
      cuisineImageUrl: cuisineImageUrl,
    );
  }
}

@freezed
abstract class Branch with _$Branch {
  const Branch._();

  const factory Branch({
    required int id,
    required String name,
    required String email,
    required String longitude,
    required String latitude,
    required String address,
    required int coverage,
    required int status,
    required String image,
    required String coverImage,
    required int preparationTime,
  }) = _Branch;

  factory Branch.fromJson(Map<String, dynamic> json) => _$BranchFromJson(json);

  BranchEntity toEntity() {
    return BranchEntity(
      id: id,
      name: name,
      email: email,
      longitude: longitude,
      latitude: latitude,
      address: address,
      coverage: coverage,
      status: status,
      image: image,
      coverImage: coverImage,
      preparationTime: preparationTime,
    );
  }
}

@freezed
abstract class CookiesManagement with _$CookiesManagement {
  const CookiesManagement._();
  const factory CookiesManagement({required int status, required String text}) = _CookiesManagement;

  factory CookiesManagement.fromJson(Map<String, dynamic> json) => _$CookiesManagementFromJson(json);

  CookiesManagementEntity toEntity() {
    return CookiesManagementEntity(status: status, text: text);
  }
}

@freezed
abstract class CustomerLogin with _$CustomerLogin {
  const CustomerLogin._();
  const factory CustomerLogin({required LoginOption loginOption, required SocialMediaLoginOptions socialMediaLoginOptions}) = _CustomerLogin;

  factory CustomerLogin.fromJson(Map<String, dynamic> json) => _$CustomerLoginFromJson(json);

  CustomerLoginEntity toEntity() {
    return CustomerLoginEntity(loginOption: loginOption.toEntity(), socialMediaLoginOptions: socialMediaLoginOptions.toEntity());
  }
}

@freezed
abstract class LoginOption with _$LoginOption {
  const LoginOption._();
  const factory LoginOption({required int manualLogin, required int otpLogin, required int socialMediaLogin}) = _LoginOption;

  factory LoginOption.fromJson(Map<String, dynamic> json) => _$LoginOptionFromJson(json);

  LoginOptionEntity toEntity() {
    return LoginOptionEntity(manualLogin: manualLogin, otpLogin: otpLogin, socialMediaLogin: socialMediaLogin);
  }
}

@freezed
abstract class SocialMediaLoginOptions with _$SocialMediaLoginOptions {
  const SocialMediaLoginOptions._();

  const factory SocialMediaLoginOptions({required int google, required int facebook, required int apple}) = _SocialMediaLoginOptions;

  factory SocialMediaLoginOptions.fromJson(Map<String, dynamic> json) => _$SocialMediaLoginOptionsFromJson(json);

  SocialMediaLoginOptionsEntity toEntity() {
    return SocialMediaLoginOptionsEntity(google: google, facebook: facebook, apple: apple);
  }
}

@freezed
abstract class CustomerVerification with _$CustomerVerification {
  const CustomerVerification._();
  const factory CustomerVerification({required int status, required int phone, required int email, required int firebase}) = _CustomerVerification;

  factory CustomerVerification.fromJson(Map<String, dynamic> json) => _$CustomerVerificationFromJson(json);

  CustomerVerificationEntity toEntity() {
    return CustomerVerificationEntity(status: status, phone: phone, email: email, firebase: firebase);
  }
}

@freezed
abstract class DeliveryManagement with _$DeliveryManagement {
  const DeliveryManagement._();
  const factory DeliveryManagement({required int status, required int minShippingCharge, required int shippingPerKm}) = _DeliveryManagement;

  factory DeliveryManagement.fromJson(Map<String, dynamic> json) => _$DeliveryManagementFromJson(json);

  DeliveryManagementEntity toEntity() {
    return DeliveryManagementEntity(status: status, minShippingCharge: minShippingCharge, shippingPerKm: shippingPerKm);
  }
}

@freezed
abstract class DigitalPaymentInfo with _$DigitalPaymentInfo {
  const DigitalPaymentInfo._();
  const factory DigitalPaymentInfo({required String digitalPayment, required String pluginPaymentGateways, required String defaultPaymentGateways}) = _DigitalPaymentInfo;

  factory DigitalPaymentInfo.fromJson(Map<String, dynamic> json) => _$DigitalPaymentInfoFromJson(json);

  DigitalPaymentInfoEntity toEntity() {
    return DigitalPaymentInfoEntity(digitalPayment: digitalPayment, pluginPaymentGateways: pluginPaymentGateways, defaultPaymentGateways: defaultPaymentGateways);
  }
}

@freezed
abstract class PromotionCampaign with _$PromotionCampaign {
  const PromotionCampaign._();
  const factory PromotionCampaign({
    required int id,
    required dynamic restaurantId,
    required String name,
    required String email,
    required String password,
    required String latitude,
    required String longitude,
    required String address,
    required int status,
    required int branchPromotionStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int coverage,
    required String? rememberToken,
    required String image,
    required String phone,
    required String coverImage,
    required int preparationTime,
    required List<BranchPromotion> branchPromotion,
  }) = _PromotionCampaign;

  factory PromotionCampaign.fromJson(Map<String, dynamic> json) => _$PromotionCampaignFromJson(json);

  PromotionCampaignEntity toEntity() {
    return PromotionCampaignEntity(
      id: id,
      restaurantId: restaurantId,
      name: name,
      email: email,
      password: password,
      latitude: latitude,
      longitude: longitude,
      address: address,
      status: status,
      branchPromotionStatus: branchPromotionStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      coverage: coverage,
      rememberToken: rememberToken,
      image: image,
      phone: phone,
      coverImage: coverImage,
      preparationTime: preparationTime,
      branchPromotion: branchPromotion.map((e) => e.toEntity()).toList(),
    );
  }
}

@freezed
abstract class BranchPromotion with _$BranchPromotion {
  const BranchPromotion._();
  const factory BranchPromotion({required int id, required int branchId, required String promotionType, required String promotionName, required DateTime createdAt, required DateTime updatedAt}) =
      _BranchPromotion;

  factory BranchPromotion.fromJson(Map<String, dynamic> json) => _$BranchPromotionFromJson(json);

  BranchPromotionEntity toEntity() {
    return BranchPromotionEntity(id: id, branchId: branchId, promotionType: promotionType, promotionName: promotionName, createdAt: createdAt, updatedAt: updatedAt);
  }
}

@freezed
abstract class RestaurantLocationCoverage with _$RestaurantLocationCoverage {
  const RestaurantLocationCoverage._();
  const factory RestaurantLocationCoverage({required String longitude, required String latitude, required int coverage}) = _RestaurantLocationCoverage;

  factory RestaurantLocationCoverage.fromJson(Map<String, dynamic> json) => _$RestaurantLocationCoverageFromJson(json);

  RestaurantLocationCoverageEntity toEntity() {
    return RestaurantLocationCoverageEntity(longitude: longitude, latitude: latitude, coverage: coverage);
  }
}

@freezed
abstract class RestaurantScheduleTime with _$RestaurantScheduleTime {
  const RestaurantScheduleTime._();
  const factory RestaurantScheduleTime({required int day, required String openingTime, required String closingTime}) = _RestaurantScheduleTime;

  factory RestaurantScheduleTime.fromJson(Map<String, dynamic> json) => _$RestaurantScheduleTimeFromJson(json);

  RestaurantScheduleTimeEntity toEntity() {
    return RestaurantScheduleTimeEntity(day: day, openingTime: openingTime, closingTime: closingTime);
  }
}

@freezed
abstract class SocialLogin with _$SocialLogin {
  const SocialLogin._();
  const factory SocialLogin({required int google, required int facebook}) = _SocialLogin;

  factory SocialLogin.fromJson(Map<String, dynamic> json) => _$SocialLoginFromJson(json);

  SocialLoginEntity toEntity() {
    return SocialLoginEntity(google: google, facebook: facebook);
  }
}

@freezed
abstract class SocialMediaLink with _$SocialMediaLink {
  const SocialMediaLink._();
  const factory SocialMediaLink({required int id, required String name, required String link, required int status, required dynamic createdAt, required dynamic updatedAt}) = _SocialMediaLink;

  factory SocialMediaLink.fromJson(Map<String, dynamic> json) => _$SocialMediaLinkFromJson(json);

  SocialMediaLinkEntity toEntity() {
    return SocialMediaLinkEntity(id: id, name: name, link: link, status: status, createdAt: createdAt, updatedAt: updatedAt);
  }
}

@freezed
abstract class Whatsapp with _$Whatsapp {
  const Whatsapp._();
  const factory Whatsapp({required int status, required String number}) = _Whatsapp;

  factory Whatsapp.fromJson(Map<String, dynamic> json) => _$WhatsappFromJson(json);

  WhatsappEntity toEntity() {
    return WhatsappEntity(status: status, number: number);
  }
}
