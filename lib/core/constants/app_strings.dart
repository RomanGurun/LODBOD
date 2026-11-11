class AppStrings {
  AppStrings._();

  static const String appName = 'LODBOD';
  static const String tagline = 'Ship Smarter';

  // Auth
  static const String login = 'Sign In';
  static const String logout = 'Sign Out';
  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle = 'Log in to manage your shipments.';
  static const String emailOrPhone = 'Email or Phone';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot password?';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String signUp = 'Sign Up';
  static const String demoEmail = 'demo@lodbod.com';
  static const String demoPhone = '9800000000';
  static const String demoPassword = 'Demo@1234';
  static const String otpTitle = 'Verify OTP';
  static const String otpSubtitle =
      'Enter the 6-digit code sent to your number';
  static const String otpResend = 'Resend OTP';
  static const String otpVerify = 'Verify';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String goodMorning = 'Good morning,';
  static const String goodAfternoon = 'Good afternoon,';
  static const String goodEvening = 'Good evening,';
  static const String activeShipments = 'Active';
  static const String pendingShipments = 'Pending';
  static const String awaitingBids = 'Awaiting Bids';
  static const String completedShipments = 'Completed';
  static const String deliveredShipments = 'Delivered';
  static const String recentShipments = 'Recent shipments';
  static const String postLoad = 'Post a Load';
  static const String postLoadCta = '+ Post Load';
  static const String seeAll = 'See all';
  static const String shipSomethingNew = 'Ship something new';
  static const String mobileRequestsUsed = 'Mobile requests used:';
  static const String of = 'of';
  static const String needsYourAction = 'Needs your action';
  static const String newBidsOn = 'new bids on';
  static const String biddingOpen = 'bidding open';
  static const String nextPickup = 'Next pickup';
  static const String details = 'Details';
  static const String loadingShipments = 'Loading your shipments...';
  static const String allCaughtUp = "You're all caught up";
  static const String noNotifications = 'No new notifications yet';

  // Shipments
  static const String shipments = 'Shipments';
  static const String searchShipments = 'Search by reference or route';
  static const String allStatus = 'All';
  static const String noShipmentsFound = 'No shipments found';
  static const String noShipmentsSubtitle =
      'Try adjusting your search or filters';
  static const String shipmentDetails = 'Shipment Details';
  static const String route = 'Route';
  static const String cargo = 'Cargo';
  static const String schedule = 'Schedule';
  static const String vehicle = 'Vehicle';
  static const String timeline = 'Status Timeline';
  static const String viewBids = 'View Bids';

  // Create Shipment
  static const String createShipment = 'Post a Load';
  static const String step1Title = 'Route';
  static const String step2Title = 'Cargo';
  static const String step3Title = 'Schedule';
  static const String step4Title = 'Vehicle';
  static const String step5Title = 'Review';
  static const String pickupLocation = 'Pickup Location';
  static const String destination = 'Destination';
  static const String cargoDescription = 'Cargo Description';
  static const String cargoCategory = 'Category';
  static const String weight = 'Weight';
  static const String weightUnit = 'Unit';
  static const String vehicleType = 'Vehicle Type';
  static const String pickupDate = 'Pickup Date';
  static const String pickupTime = 'Pickup Time';
  static const String expectedFare = 'Expected Fare (Optional)';
  static const String notes = 'Notes (Optional)';
  static const String next = 'Next';
  static const String previous = 'Back';
  static const String reviewAndSubmit = 'Review & Submit';
  static const String submit = 'Submit';
  static const String submitting = 'Submitting...';
  static const String shipmentCreated = 'Shipment Created!';
  static const String shipmentCreatedSubtitle =
      'Your shipment has been posted successfully.';

  // 3-Request Limit
  static const String requestLimitTitle = 'Request Limit Reached';
  static const String requestLimitMessage =
      'You have reached the mobile request limit of 3. '
      'Please use the LODBOD web platform to create additional requests.';
  static const String gotIt = 'Got It';

  // Bids
  static const String bids = 'Carrier Bids';
  static const String noBids = 'No bids yet';
  static const String noBidsSubtitle = 'Carriers will submit offers shortly';
  static const String acceptBid = 'Accept Bid';
  static const String acceptBidConfirmTitle = 'Accept this bid?';
  static const String acceptBidConfirmMessage =
      'You are about to accept the bid from {carrier} for {fare}. This action cannot be undone.';
  static const String confirm = 'Confirm';
  static const String cancel = 'Cancel';
  static const String bidAccepted = 'Bid accepted successfully!';

  // Carrier-side demo actions
  static const String simulateBid = 'Simulate Carrier Bid';
  static const String simulating = 'Simulating...';
  static const String simulateBidConfirmTitle = 'Simulate a carrier bid?';
  static const String simulateBidConfirmMessage =
      'This prototype ships only the shipper app — there is no carrier side '
      'to place bids. This demo control posts a fictional carrier bid '
      'through the real API so the full lifecycle can be demonstrated.';
  static const String bidSimulated = 'New bid from {carrier} for {fare}';
  static const String advanceStatusButton = 'Mark as {status}';
  static const String advancing = 'Updating...';
  static const String advanceStatusConfirmTitle = 'Update shipment status?';
  static const String advanceStatusConfirmMessage =
      'Mark {reference} as {status}? In the full product the carrier makes '
      'this update after pickup and delivery.';
  static const String statusAdvanced = '{reference} is now {status}';
  static const String demoControlNote =
      'Demo control — stands in for the carrier side';

  // Analytics
  static const String analytics = 'Analytics';

  // Account
  static const String account = 'Account';
  static const String profile = 'Profile';
  static const String settings = 'Settings';

  // Status labels
  static const String statusOpen = 'Open';
  static const String statusAwaitingBids = 'Awaiting Bids';
  static const String statusScheduled = 'Scheduled';
  static const String statusConfirmed = 'Confirmed';
  static const String statusInTransit = 'In-transit';
  static const String statusDelivered = 'Delivered';
  static const String statusCancelled = 'Cancelled';
  static const String statusExpired = 'Expired';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError =
      'No internet connection. Please check your network.';
  static const String retry = 'Retry';
  static const String fieldRequired = 'This field is required';
  static const String invalidEmail = 'Enter a valid email address';
  static const String invalidPhone = 'Enter a valid 10-digit phone number';
  static const String sameLocationError =
      'Pickup and destination cannot be the same';
  static const String pastDateError = 'Pickup date cannot be in the past';
  static const String invalidWeight = 'Weight must be a positive number';
  static const String invalidCredentials = 'Invalid email/phone or password';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';

  // API
  static const String baseUrl = 'https://YOUR_MOCKAPI_ID.mockapi.io/api/v1';
}
