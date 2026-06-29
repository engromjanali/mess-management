import 'package:equatable/equatable.dart';

class ConfigEntity extends Equatable {
  final String restaurantName;
  final String restaurantPhone;
  final List<RestaurantScheduleTimeEntity> restaurantScheduleTime;
  final String restaurantLogo;
  final String restaurantAddress;
  final String restaurantEmail;
  final RestaurantLocationCoverageEntity restaurantLocationCoverage;
  final int minimumOrderValue;
  final BaseUrlsEntity baseUrls;
  final String currencySymbol;
  final double deliveryCharge;
  final DeliveryManagementEntity deliveryManagement;
  final List<BranchEntity> branches;
  final bool emailVerification;
  final bool phoneVerification;
  final String currencySymbolPosition;
  final String country;
  final bool selfPickup;
  final bool delivery;
  final StoreConfigEntity playStoreConfig;
  final StoreConfigEntity appStoreConfig;
  final List<SocialMediaLinkEntity> socialMediaLink;
  final String softwareVersion;
  final int decimalPointSettings;
  final int scheduleOrderSlotDuration;
  final String timeFormat;
  final List<PromotionCampaignEntity> promotionCampaign;
  final SocialLoginEntity socialLogin;
  final int walletStatus;
  final int loyaltyPointStatus;
  final int refEarningStatus;
  final int loyaltyPointItemPurchasePoint;
  final int loyaltyPointExchangeRate;
  final int loyaltyPointMinimumPoint;
  final int customerReferredDiscountStatus;
  final String customerReferredDiscountType;
  final int customerReferredDiscountAmount;
  final String customerReferredValidityType;
  final int customerReferredValidityValue;
  final WhatsappEntity whatsapp;
  final CookiesManagementEntity cookiesManagement;
  final int toggleDmRegistration;
  final int isVegNonVegActive;
  final int otpResendTime;
  final DigitalPaymentInfoEntity digitalPaymentInfo;
  final int digitalPaymentStatus;
  final List<ActivePaymentMethodListEntity> activePaymentMethodList;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isOfflinePaymentActive;
  final bool isGuestCheckoutActive;
  final bool isPartialPaymentActive;
  final String partialPaymentCombineWith;
  final bool isAddFundToWalletActive;
  final AppleLoginEntity appleLogin;
  final bool isCutleryActive;
  final bool isFirebaseOtpVerificationActive;
  final CustomerVerificationEntity customerVerification;
  final String footerCopyrightText;
  final String footerDescriptionText;
  final CustomerLoginEntity customerLogin;
  final int googleMapStatus;
  final bool maintenanceMode;
  final AdvanceMaintenanceModeEntity advanceMaintenanceMode;
  final bool isHalalTagActive;
  final int maxImageUploadSize;
  final List<AcceptedImageExtensionArrayEntity> acceptedImageExtensionArray;
  final List<String> acceptedImageExtension;

  const ConfigEntity({
    required this.restaurantName,
    required this.restaurantPhone,
    required this.restaurantScheduleTime,
    required this.restaurantLogo,
    required this.restaurantAddress,
    required this.restaurantEmail,
    required this.restaurantLocationCoverage,
    required this.minimumOrderValue,
    required this.baseUrls,
    required this.currencySymbol,
    required this.deliveryCharge,
    required this.deliveryManagement,
    required this.branches,
    required this.emailVerification,
    required this.phoneVerification,
    required this.currencySymbolPosition,
    required this.country,
    required this.selfPickup,
    required this.delivery,
    required this.playStoreConfig,
    required this.appStoreConfig,
    required this.socialMediaLink,
    required this.softwareVersion,
    required this.decimalPointSettings,
    required this.scheduleOrderSlotDuration,
    required this.timeFormat,
    required this.promotionCampaign,
    required this.socialLogin,
    required this.walletStatus,
    required this.loyaltyPointStatus,
    required this.refEarningStatus,
    required this.loyaltyPointItemPurchasePoint,
    required this.loyaltyPointExchangeRate,
    required this.loyaltyPointMinimumPoint,
    required this.customerReferredDiscountStatus,
    required this.customerReferredDiscountType,
    required this.customerReferredDiscountAmount,
    required this.customerReferredValidityType,
    required this.customerReferredValidityValue,
    required this.whatsapp,
    required this.cookiesManagement,
    required this.toggleDmRegistration,
    required this.isVegNonVegActive,
    required this.otpResendTime,
    required this.digitalPaymentInfo,
    required this.digitalPaymentStatus,
    required this.activePaymentMethodList,
    required this.isCashOnDeliveryActive,
    required this.isDigitalPaymentActive,
    required this.isOfflinePaymentActive,
    required this.isGuestCheckoutActive,
    required this.isPartialPaymentActive,
    required this.partialPaymentCombineWith,
    required this.isAddFundToWalletActive,
    required this.appleLogin,
    required this.isCutleryActive,
    required this.isFirebaseOtpVerificationActive,
    required this.customerVerification,
    required this.footerCopyrightText,
    required this.footerDescriptionText,
    required this.customerLogin,
    required this.googleMapStatus,
    required this.maintenanceMode,
    required this.advanceMaintenanceMode,
    required this.isHalalTagActive,
    required this.maxImageUploadSize,
    required this.acceptedImageExtensionArray,
    required this.acceptedImageExtension,
  });

  @override
  List<Object?> get props => [
    restaurantName,
    restaurantPhone,
    restaurantScheduleTime,
    restaurantLogo,
    restaurantAddress,
    restaurantEmail,
    restaurantLocationCoverage,
    minimumOrderValue,
    baseUrls,
    currencySymbol,
    deliveryCharge,
    deliveryManagement,
    branches,
    emailVerification,
    phoneVerification,
    currencySymbolPosition,
    country,
    selfPickup,
    delivery,
    playStoreConfig,
    appStoreConfig,
    socialMediaLink,
    softwareVersion,
    decimalPointSettings,
    scheduleOrderSlotDuration,
    timeFormat,
    promotionCampaign,
    socialLogin,
    walletStatus,
    loyaltyPointStatus,
    refEarningStatus,
    loyaltyPointItemPurchasePoint,
    loyaltyPointExchangeRate,
    loyaltyPointMinimumPoint,
    customerReferredDiscountStatus,
    customerReferredDiscountType,
    customerReferredDiscountAmount,
    customerReferredValidityType,
    customerReferredValidityValue,
    whatsapp,
    cookiesManagement,
    toggleDmRegistration,
    isVegNonVegActive,
    otpResendTime,
    digitalPaymentInfo,
    digitalPaymentStatus,
    activePaymentMethodList,
    isCashOnDeliveryActive,
    isDigitalPaymentActive,
    isOfflinePaymentActive,
    isGuestCheckoutActive,
    isPartialPaymentActive,
    partialPaymentCombineWith,
    isAddFundToWalletActive,
    appleLogin,
    isCutleryActive,
    isFirebaseOtpVerificationActive,
    customerVerification,
    footerCopyrightText,
    footerDescriptionText,
    customerLogin,
    googleMapStatus,
    maintenanceMode,
    advanceMaintenanceMode,
    isHalalTagActive,
    maxImageUploadSize,
    acceptedImageExtensionArray,
    acceptedImageExtension,
  ];
}

class RestaurantScheduleTimeEntity extends Equatable {
  final int day;
  final String openingTime;
  final String closingTime;

  const RestaurantScheduleTimeEntity({required this.day, required this.openingTime, required this.closingTime});

  @override
  List<Object?> get props => [day, openingTime, closingTime];
}

class RestaurantLocationCoverageEntity extends Equatable {
  final String longitude;
  final String latitude;
  final int coverage;

  const RestaurantLocationCoverageEntity({required this.longitude, required this.latitude, required this.coverage});

  @override
  List<Object?> get props => [longitude, latitude, coverage];
}

class BaseUrlsEntity extends Equatable {
  final String productImageUrl;
  final String customerImageUrl;
  final String bannerImageUrl;
  final String categoryImageUrl;
  final String categoryBannerImageUrl;
  final String reviewImageUrl;
  final String notificationImageUrl;
  final String restaurantImageUrl;
  final String deliveryManImageUrl;
  final String chatImageUrl;
  final String promotionalUrl;
  final String kitchenImageUrl;
  final String branchImageUrl;
  final String gatewayImageUrl;
  final String paymentImageUrl;
  final String cuisineImageUrl;

  const BaseUrlsEntity({
    required this.productImageUrl,
    required this.customerImageUrl,
    required this.bannerImageUrl,
    required this.categoryImageUrl,
    required this.categoryBannerImageUrl,
    required this.reviewImageUrl,
    required this.notificationImageUrl,
    required this.restaurantImageUrl,
    required this.deliveryManImageUrl,
    required this.chatImageUrl,
    required this.promotionalUrl,
    required this.kitchenImageUrl,
    required this.branchImageUrl,
    required this.gatewayImageUrl,
    required this.paymentImageUrl,
    required this.cuisineImageUrl,
  });

  @override
  List<Object?> get props => [
    productImageUrl,
    customerImageUrl,
    bannerImageUrl,
    categoryImageUrl,
    categoryBannerImageUrl,
    reviewImageUrl,
    notificationImageUrl,
    restaurantImageUrl,
    deliveryManImageUrl,
    chatImageUrl,
    promotionalUrl,
    kitchenImageUrl,
    branchImageUrl,
    gatewayImageUrl,
    paymentImageUrl,
    cuisineImageUrl,
  ];
}

class DeliveryManagementEntity extends Equatable {
  final int status;
  final int minShippingCharge;
  final int shippingPerKm;

  const DeliveryManagementEntity({required this.status, required this.minShippingCharge, required this.shippingPerKm});

  @override
  List<Object?> get props => [status, minShippingCharge, shippingPerKm];
}

class BranchEntity extends Equatable {
  final int id;
  final String name;
  final String email;
  final String longitude;
  final String latitude;
  final String address;
  final int coverage;
  final int status;
  final String image;
  final String coverImage;
  final int preparationTime;

  const BranchEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.longitude,
    required this.latitude,
    required this.address,
    required this.coverage,
    required this.status,
    required this.image,
    required this.coverImage,
    required this.preparationTime,
  });

  @override
  List<Object?> get props => [id, name, email, longitude, latitude, address, coverage, status, image, coverImage, preparationTime];
}

class StoreConfigEntity extends Equatable {
  final bool status;
  final String link;
  final String minVersion;

  const StoreConfigEntity({required this.status, required this.link, required this.minVersion});

  @override
  List<Object?> get props => [status, link, minVersion];
}

class SocialMediaLinkEntity extends Equatable {
  final int id;
  final String name;
  final String link;
  final int status;
  final dynamic createdAt;
  final dynamic updatedAt;

  const SocialMediaLinkEntity({required this.id, required this.name, required this.link, required this.status, this.createdAt, this.updatedAt});

  @override
  List<Object?> get props => [id, name, link, status, createdAt, updatedAt];
}

class PromotionCampaignEntity extends Equatable {
  final int id;
  final dynamic restaurantId;
  final String name;
  final String email;
  final String password;
  final String latitude;
  final String longitude;
  final String address;
  final int status;
  final int branchPromotionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int coverage;
  final String? rememberToken;
  final String image;
  final String phone;
  final String coverImage;
  final int preparationTime;
  final List<BranchPromotionEntity> branchPromotion;

  const PromotionCampaignEntity({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.email,
    required this.password,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.status,
    required this.branchPromotionStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.coverage,
    required this.rememberToken,
    required this.image,
    required this.phone,
    required this.coverImage,
    required this.preparationTime,
    required this.branchPromotion,
  });

  @override
  List<Object?> get props => [
    id,
    restaurantId,
    name,
    email,
    password,
    latitude,
    longitude,
    address,
    status,
    branchPromotionStatus,
    createdAt,
    updatedAt,
    coverage,
    rememberToken,
    image,
    phone,
    coverImage,
    preparationTime,
    branchPromotion,
  ];
}

class BranchPromotionEntity extends Equatable {
  final int id;
  final int branchId;
  final String promotionType;
  final String promotionName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BranchPromotionEntity({required this.id, required this.branchId, required this.promotionType, required this.promotionName, required this.createdAt, required this.updatedAt});

  @override
  List<Object?> get props => [id, branchId, promotionType, promotionName, createdAt, updatedAt];
}

class SocialLoginEntity extends Equatable {
  final int google;
  final int facebook;

  const SocialLoginEntity({required this.google, required this.facebook});

  @override
  List<Object?> get props => [google, facebook];
}

class WhatsappEntity extends Equatable {
  final int status;
  final String number;

  const WhatsappEntity({required this.status, required this.number});

  @override
  List<Object?> get props => [status, number];
}

class CookiesManagementEntity extends Equatable {
  final int status;
  final String text;

  const CookiesManagementEntity({required this.status, required this.text});

  @override
  List<Object?> get props => [status, text];
}

class DigitalPaymentInfoEntity extends Equatable {
  final String digitalPayment;
  final String pluginPaymentGateways;
  final String defaultPaymentGateways;

  const DigitalPaymentInfoEntity({required this.digitalPayment, required this.pluginPaymentGateways, required this.defaultPaymentGateways});

  @override
  List<Object?> get props => [digitalPayment, pluginPaymentGateways, defaultPaymentGateways];
}

class ActivePaymentMethodListEntity extends Equatable {
  final String gateway;
  final String gatewayTitle;
  final String gatewayImage;

  const ActivePaymentMethodListEntity({required this.gateway, required this.gatewayTitle, required this.gatewayImage});

  @override
  List<Object?> get props => [gateway, gatewayTitle, gatewayImage];
}

class AppleLoginEntity extends Equatable {
  final String loginMedium;
  final int status;
  final String clientId;

  const AppleLoginEntity({required this.loginMedium, required this.status, required this.clientId});

  @override
  List<Object?> get props => [loginMedium, status, clientId];
}

class CustomerVerificationEntity extends Equatable {
  final int status;
  final int phone;
  final int email;
  final int firebase;

  const CustomerVerificationEntity({required this.status, required this.phone, required this.email, required this.firebase});

  @override
  List<Object?> get props => [status, phone, email, firebase];
}

class CustomerLoginEntity extends Equatable {
  final LoginOptionEntity loginOption;
  final SocialMediaLoginOptionsEntity socialMediaLoginOptions;

  const CustomerLoginEntity({required this.loginOption, required this.socialMediaLoginOptions});

  @override
  List<Object?> get props => [loginOption, socialMediaLoginOptions];
}

class LoginOptionEntity extends Equatable {
  final int manualLogin;
  final int otpLogin;
  final int socialMediaLogin;

  const LoginOptionEntity({required this.manualLogin, required this.otpLogin, required this.socialMediaLogin});

  @override
  List<Object?> get props => [manualLogin, otpLogin, socialMediaLogin];
}

class SocialMediaLoginOptionsEntity extends Equatable {
  final int google;
  final int facebook;
  final int apple;

  const SocialMediaLoginOptionsEntity({required this.google, required this.facebook, required this.apple});

  @override
  List<Object?> get props => [google, facebook, apple];
}

class AdvanceMaintenanceModeEntity extends Equatable {
  final int maintenanceStatus;
  final SelectedMaintenanceSystemEntity selectedMaintenanceSystem;
  final MaintenanceMessagesEntity maintenanceMessages;
  final MaintenanceTypeAndDurationEntity maintenanceTypeAndDuration;

  const AdvanceMaintenanceModeEntity({required this.maintenanceStatus, required this.selectedMaintenanceSystem, required this.maintenanceMessages, required this.maintenanceTypeAndDuration});

  @override
  List<Object?> get props => [maintenanceStatus, selectedMaintenanceSystem, maintenanceMessages, maintenanceTypeAndDuration];
}

class SelectedMaintenanceSystemEntity extends Equatable {
  final int branchPanel;
  final int customerApp;
  final int webApp;
  final int deliverymanApp;

  const SelectedMaintenanceSystemEntity({required this.branchPanel, required this.customerApp, required this.webApp, required this.deliverymanApp});

  @override
  List<Object?> get props => [branchPanel, customerApp, webApp, deliverymanApp];
}

class MaintenanceMessagesEntity extends Equatable {
  final int businessNumber;
  final int businessEmail;
  final String maintenanceMessage;
  final String messageBody;

  const MaintenanceMessagesEntity({required this.businessNumber, required this.businessEmail, required this.maintenanceMessage, required this.messageBody});

  @override
  List<Object?> get props => [businessNumber, businessEmail, maintenanceMessage, messageBody];
}

class MaintenanceTypeAndDurationEntity extends Equatable {
  final String maintenanceDuration;
  final dynamic startDate;
  final dynamic endDate;

  const MaintenanceTypeAndDurationEntity({required this.maintenanceDuration, required this.startDate, required this.endDate});

  @override
  List<Object?> get props => [maintenanceDuration, startDate, endDate];
}

class AcceptedImageExtensionArrayEntity extends Equatable {
  final String key;
  final String value;

  const AcceptedImageExtensionArrayEntity({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}
